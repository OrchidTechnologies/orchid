/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2020  The Orchid Authors
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
#include "fit.hpp"
#include "forge.hpp"

namespace orc {

Socket Egress::Translator::Translate(const Three &source) {
    { const auto locked(locked_());
        const auto internal(locked->internals_.find(source));
        if (internal != locked->internals_.end())
            return internal->second.translated_; }
    return egress_->Translate(indirect_, source);
}

Socket Egress::Translate(Translators::iterator translator, const Three &source) {
    const auto locked(locked_());
    auto &externals(locked->externals_);
    auto &recents(locked->recents_);

    if (const auto translated = translator->first->Access([&](auto &internals) -> std::optional<Socket> {
        const auto internal(internals.find(source));
        if (internal == internals.end())
            return {};
        return {{Socket(internal->second.translated_)}};
    }))
        return *translated;

    auto ephemeral(ephemeral_ + recents.size());
    if (ephemeral == 0x10000) {
        const auto recent(recents.back());
        recents.pop_back();
        ephemeral = recent.Port();

        const auto external(externals.find(recent));
        if (external != externals.end()) {
            external->second.indirect_->first->Access([&](auto &internals) {
                orc_insist(internals.erase(Three(recent.Protocol(), external->second.translated_)) != 0);
            });
            externals.erase(external);
        }
    }

    const auto translated(Three(source.Protocol(), local_, Fit(ephemeral)));
    recents.emplace_front(translated);
    const auto external(externals.emplace(translated, External{source.Two(), translator, recents.begin()}));
    orc_insist(external.second);
    translator->first->Access([&](auto &internals) {
        orc_insist(internals.emplace(source, Internal{translated.Two(), external.first}).second);
    });
    return translated.Two();
}

std::optional<Egress::Translation> Egress::Find(const Three &destination) {
    const auto locked(locked_());
    const auto external(locked->externals_.find(destination));
    if (external == locked->externals_.end())
        return {};
    auto &recents(locked->recents_);
    recents.splice(recents.begin(), recents, external->second.recent_);
    ++external->second.indirect_->second->usage_;
    return {Translation(external->second.translated_, *external->second.indirect_->first, external->second.indirect_->second)};
}

Egress::Translators::iterator Egress::Open(Translator *translator, Neutral *neutral) {
    const auto locked(locked_());
    const auto emplaced(locked->translators_.try_emplace(translator, neutral));
    orc_insist(emplaced.second);
    return emplaced.first;
}

task<void> Egress::Shut(Translators::iterator indirect) noexcept {
    const auto translator(indirect->first);
    auto &neutral(*indirect->second);

    {
        const auto locked(locked_());
        auto &externals(locked->externals_);
        auto &recents(locked->recents_);

        translator->Access([&](auto &internals) {
            for (const auto &[source, internal] : internals) {
                const auto external(internal.external_);
                orc_insist(external->second.indirect_ == indirect);
                recents.splice(recents.begin(), recents, external->second.recent_);
                externals.erase(external);
            }

            internals.clear();
        });

        locked->translators_.erase(indirect);

        neutral.shutting_ = true;
        if (neutral.usage_ == 0)
            neutral.shut_();
    }

    co_await *neutral.shut_;
    translator->Stop();
}

task<void> Egress::Translator::Send(const Buffer &data) {
    Beam beam(data);
    auto span(beam.span());
    auto &ip4(span.cast<openvpn::IPv4Header>());
    const auto length(openvpn::IPv4Header::length(ip4.version_len));

    switch (ip4.protocol) {
        case openvpn::IPCommon::TCP: {
            auto &tcp(span.cast<openvpn::TCPHeader>(length));
            const Three source(openvpn::IPCommon::TCP, boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(tcp.source));
            const auto translated(Translate(source));
            ForgeIP4(span, &openvpn::IPv4Header::saddr, translated.Host().operator uint32_t());
            Forge(tcp, &openvpn::TCPHeader::source, translated.Port());
            co_return co_await egress_->Send(beam);
        } break;

        case openvpn::IPCommon::UDP: {
            auto &udp(span.cast<openvpn::UDPHeader>(length));
            const Three source(openvpn::IPCommon::UDP, boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(udp.source));
            const auto translated(Translate(source));
            ForgeIP4(span, &openvpn::IPv4Header::saddr, translated.Host().operator uint32_t());
            Forge(udp, &openvpn::UDPHeader::source, translated.Port());
            co_return co_await egress_->Send(beam);
        } break;

        case openvpn::IPCommon::ICMPv4: {
            auto &icmp(span.cast<openvpn::ICMPv4>());
            const Three source(openvpn::IPCommon::ICMPv4, boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(icmp.id));
            const auto translated(Translate(source));
            ForgeIP4(span, &openvpn::IPv4Header::saddr, translated.Host().operator uint32_t());
            Forge(icmp, &openvpn::ICMPv4::id, translated.Port());
            co_return co_await egress_->Send(beam);
        } break;
    }
}

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
                ForgeIP4(span, &openvpn::IPv4Header::daddr, translation->translated_.Host().operator uint32_t());
                Forge(tcp, &openvpn::TCPHeader::dest, translation->translated_.Port());
                return translation->translator_.Land(beam);
            }
        } break;

        case openvpn::IPCommon::UDP: {
            auto &udp(span.cast<openvpn::UDPHeader>(length));
            const Three destination(openvpn::IPCommon::UDP, boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(udp.dest));
            if (const auto translation = Find(destination)) {
                ForgeIP4(span, &openvpn::IPv4Header::daddr, translation->translated_.Host().operator uint32_t());
                Forge(udp, &openvpn::UDPHeader::dest, translation->translated_.Port());
                return translation->translator_.Land(beam);
            }
        } break;

        case openvpn::IPCommon::ICMPv4: {
            auto &icmp(span.cast<openvpn::ICMPv4>());
            const Three destination(openvpn::IPCommon::ICMPv4, boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(icmp.id));
            if (const auto translation = Find(destination)) {
                ForgeIP4(span, &openvpn::IPv4Header::daddr, translation->translated_.Host().operator uint32_t());
                Forge(icmp, &openvpn::ICMPv4::id, translation->translated_.Port());
                return translation->translator_.Land(beam);
            }
        } break;
    }
}

void Egress::Stop(const std::string &error) noexcept {
    const auto locked(locked_());
    for (const auto &translator : locked->translators_)
        translator.first->Stop(error);
}

}
