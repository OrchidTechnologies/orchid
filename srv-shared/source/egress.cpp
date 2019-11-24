/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2019  The Orchid Authors
*/

/* GNU Affero General Public License, Version 3 {{{ */
/*
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.

 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
**/
/* }}} */


#include "egress.hpp"
#include "forge.hpp"

namespace orc {

void Egress::Land(const Buffer &data) {
    Beam beam(data);
    auto span(beam.span());
    auto &ip4(span.cast<openvpn::IPv4Header>());
    auto length(openvpn::IPv4Header::length(ip4.version_len));

    switch (ip4.protocol) {
        case openvpn::IPCommon::TCP: {
            auto &tcp(span.cast<openvpn::TCPHeader>(length));
            Three destination(openvpn::IPCommon::TCP, boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(tcp.dest));
            auto translation(Find(destination));
            if (translation == translations_.end())
                return;
            const auto &replace(translation->second.socket_);
            ForgeIP4(span, &openvpn::IPv4Header::daddr, replace.Host());
            Forge(tcp, &openvpn::TCPHeader::dest, replace.Port());
            return translation->second.translator_->Land(beam);
        } break;

        case openvpn::IPCommon::UDP: {
            auto &udp(span.cast<openvpn::UDPHeader>(length));
            Three destination(openvpn::IPCommon::UDP, boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(udp.dest));
            auto translation(Find(destination));
            if (translation == translations_.end())
                return;
            const auto &replace(translation->second.socket_);
            ForgeIP4(span, &openvpn::IPv4Header::daddr, replace.Host());
            Forge(udp, &openvpn::UDPHeader::dest, replace.Port());
            return translation->second.translator_->Land(beam);
        } break;

        case openvpn::IPCommon::ICMPv4: {
            auto &icmp(span.cast<openvpn::ICMPv4>());
            // NOLINTNEXTLINE (cppcoreguidelines-pro-type-union-access)
            Three destination(openvpn::IPCommon::ICMPv4, boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(icmp.id));
            auto translation(Find(destination));
            if (translation == translations_.end())
                return;
            const auto &replace(translation->second.socket_);
            ForgeIP4(span, &openvpn::IPv4Header::daddr, replace.Host());
            Forge(icmp, &openvpn::ICMPv4::id, replace.Port());
            return translation->second.translator_->Land(beam);
        } break;
    }
}

void Egress::Stop(const std::string &error) {
    std::unique_lock<std::mutex> lock(mutex_);
    for (auto translation : translations_)
        translation.second.translator_->Stop(error);
}

Egress::Translations_::iterator Egress::Find(const Three &target) {
    std::unique_lock<std::mutex> lock(mutex_);
    auto translation_iter(translations_.find(target));
    if (translation_iter != translations_.end()) {
        lru_.erase(translation_iter->second.lru_iter_);
        lru_.push_back(translation_iter->first);
        translation_iter->second.lru_iter_ = std::prev(lru_.end());
    }
    return translation_iter;
}

const Socket &Egress::Translate(Translator *translator, const Three &three) {
    auto ephemeral(ephemeral_base_ + translations_.size());
    if (ephemeral >= 65535) {
        auto old_three(*lru_.begin());
        auto old_translation_iter(translations_.find(old_three));
        orc_insist(old_translation_iter != translations_.end());
        ephemeral = old_three.Port();
        auto old_translation(old_translation_iter->second);
        old_translation.translator_->Remove(Three(old_three.Protocol(), old_translation.socket_));
        translations_.erase(old_translation_iter);
        lru_.pop_front();
    }
    auto new_three(Three(three.Protocol(), local_, ephemeral));
    lru_.push_back(new_three);
    auto lru_iter(std::prev(lru_.end()));
    auto translation(translations_.emplace(new_three, Translation_{three.Two(), translator, lru_iter}));
    orc_insist(translation.second);
    return translation.first->first;
}

task<void> Translator::Send(const Buffer &data) {
    std::unique_lock<std::mutex> lock(mutex_);
    Beam beam(data);
    auto span(beam.span());
    auto &ip4(span.cast<openvpn::IPv4Header>());
    auto length(openvpn::IPv4Header::length(ip4.version_len));

    switch (ip4.protocol) {
        case openvpn::IPCommon::TCP: {
            auto &tcp(span.cast<openvpn::TCPHeader>(length));
            Three source(openvpn::IPCommon::TCP, boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(tcp.source));
            auto translation(translations_.find(source));
            if (translation == translations_.end())
                translation = Translate(source);
            const auto &replace(translation->second);
            ForgeIP4(span, &openvpn::IPv4Header::saddr, replace.Host());
            Forge(tcp, &openvpn::TCPHeader::source, replace.Port());
            co_return co_await egress_->Send(beam);
        } break;

        case openvpn::IPCommon::UDP: {
            auto &udp(span.cast<openvpn::UDPHeader>(length));
            Three source(openvpn::IPCommon::UDP, boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(udp.source));
            auto translation(translations_.find(source));
            if (translation == translations_.end())
                translation = Translate(source);
            const auto &replace(translation->second);
            ForgeIP4(span, &openvpn::IPv4Header::saddr, replace.Host());
            Forge(udp, &openvpn::UDPHeader::source, replace.Port());
            co_return co_await egress_->Send(beam);
        } break;

        case openvpn::IPCommon::ICMPv4: {
            auto &icmp(span.cast<openvpn::ICMPv4>());
            // NOLINTNEXTLINE (cppcoreguidelines-pro-type-union-access)
            Three source(openvpn::IPCommon::ICMPv4, boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(icmp.id));
            auto translation(translations_.find(source));
            if (translation == translations_.end())
                translation = Translate(source);
            const auto &replace(translation->second);
            ForgeIP4(span, &openvpn::IPv4Header::saddr, replace.Host());
            Forge(icmp, &openvpn::ICMPv4::id, replace.Port());
            co_return co_await egress_->Send(beam);
        } break;
    }
}


}
