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
    const auto length(openvpn::IPv4Header::length(ip4.version_len));

    switch (ip4.protocol) {
        case openvpn::IPCommon::TCP: {
            auto &tcp(span.cast<openvpn::TCPHeader>(length));
            const Three destination(openvpn::IPCommon::TCP, boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(tcp.dest));
            if (const auto translation = Find(destination)) {
                const auto &[replace, translator] = *translation;
                ForgeIP4(span, &openvpn::IPv4Header::daddr, replace.Host());
                Forge(tcp, &openvpn::TCPHeader::dest, replace.Port());
                return translator.Land(beam);
            }
        } break;

        case openvpn::IPCommon::UDP: {
            auto &udp(span.cast<openvpn::UDPHeader>(length));
            const Three destination(openvpn::IPCommon::UDP, boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(udp.dest));
            if (const auto translation = Find(destination)) {
                const auto &[replace, translator] = *translation;
                ForgeIP4(span, &openvpn::IPv4Header::daddr, replace.Host());
                Forge(udp, &openvpn::UDPHeader::dest, replace.Port());
                return translator.Land(beam);
            }
        } break;

        case openvpn::IPCommon::ICMPv4: {
            auto &icmp(span.cast<openvpn::ICMPv4>());
            // NOLINTNEXTLINE (cppcoreguidelines-pro-type-union-access)
            const Three destination(openvpn::IPCommon::ICMPv4, boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(icmp.id));
            if (const auto translation = Find(destination)) {
                const auto &[replace, translator] = *translation;
                ForgeIP4(span, &openvpn::IPv4Header::daddr, replace.Host());
                Forge(icmp, &openvpn::ICMPv4::id, replace.Port());
                return translator.Land(beam);
            }
        } break;
    }
}

void Egress::Stop(const std::string &error) noexcept {
    const auto locked(locked_());
    for (auto translation : locked->translations_)
        translation.second.translator_.Stop(error);
}

std::optional<std::pair<const Socket, Translator &>> Egress::Find(const Three &target) {
    const auto locked(locked_());
    const auto translation_iter(locked->translations_.find(target));
    if (translation_iter == locked->translations_.end())
        return {};
    locked->lru_.erase(translation_iter->second.lru_iter_);
    locked->lru_.push_back(translation_iter->first);
    translation_iter->second.lru_iter_ = std::prev(locked->lru_.end());
    return {{translation_iter->second.socket_, std::ref(translation_iter->second.translator_)}};
}

Socket Egress::Translate(Translator &translator, const Three &three) {
    const auto locked(locked_());
    auto ephemeral(ephemeral_base_ + locked->translations_.size());
    if (ephemeral >= 65535) {
        auto old_three(*locked->lru_.begin());
        auto old_translation_iter(locked->translations_.find(old_three));
        orc_insist(old_translation_iter != locked->translations_.end());
        ephemeral = old_three.Port();
        auto old_translation(old_translation_iter->second);
        old_translation.translator_.Remove(Three(old_three.Protocol(), old_translation.socket_));
        locked->translations_.erase(old_translation_iter);
        locked->lru_.pop_front();
    }
    const auto new_three(Three(three.Protocol(), local_, ephemeral));
    locked->lru_.push_back(new_three);
    const auto lru_iter(std::prev(locked->lru_.end()));
    orc_assert(locked->translations_.emplace(new_three, Translation_{three.Two(), translator, lru_iter}).second);
    return new_three.Two();
}

task<void> Translator::Send(const Buffer &data) {
    Beam beam(data);
    auto span(beam.span());
    auto &ip4(span.cast<openvpn::IPv4Header>());
    const auto length(openvpn::IPv4Header::length(ip4.version_len));

    switch (ip4.protocol) {
        case openvpn::IPCommon::TCP: {
            auto &tcp(span.cast<openvpn::TCPHeader>(length));
            const Three source(openvpn::IPCommon::TCP, boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(tcp.source));
            const auto replace(Translate(source));
            ForgeIP4(span, &openvpn::IPv4Header::saddr, replace.Host());
            Forge(tcp, &openvpn::TCPHeader::source, replace.Port());
            co_return co_await egress_->Send(beam);
        } break;

        case openvpn::IPCommon::UDP: {
            auto &udp(span.cast<openvpn::UDPHeader>(length));
            const Three source(openvpn::IPCommon::UDP, boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(udp.source));
            const auto replace(Translate(source));
            ForgeIP4(span, &openvpn::IPv4Header::saddr, replace.Host());
            Forge(udp, &openvpn::UDPHeader::source, replace.Port());
            co_return co_await egress_->Send(beam);
        } break;

        case openvpn::IPCommon::ICMPv4: {
            auto &icmp(span.cast<openvpn::ICMPv4>());
            // NOLINTNEXTLINE (cppcoreguidelines-pro-type-union-access)
            const Three source(openvpn::IPCommon::ICMPv4, boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(icmp.id));
            const auto replace(Translate(source));
            ForgeIP4(span, &openvpn::IPv4Header::saddr, replace.Host());
            Forge(icmp, &openvpn::ICMPv4::id, replace.Port());
            co_return co_await egress_->Send(beam);
        } break;
    }
}


}
