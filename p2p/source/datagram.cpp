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


#include <openvpn/ip/csum.hpp>
#include <openvpn/ip/ip4.hpp>
#include <openvpn/ip/udp.hpp>

#include "datagram.hpp"
#include "syscall.hpp"

namespace orc {

bool Datagram(const Buffer &data, const std::function<bool (Socket, Socket, Window)> &code) {
    Window window(data);

    openvpn::IPv4Header ip4;
    window.Take(&ip4);
    window.Skip(openvpn::IPv4Header::length(ip4.version_len) - sizeof(ip4));

    if (ip4.protocol != uint8_t(openvpn::IPCommon::UDP))
        return false;

    openvpn::UDPHeader udp;
    window.Take(&udp);
    window.Skip(boost::endian::big_to_native(udp.len) - sizeof(udp));

    Socket source(boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(udp.source));
    Socket target(boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(udp.dest));

    return code(std::move(source), std::move(target), std::move(window));
}

void Datagram(const Socket &source, const Socket &target, const Buffer &data, const std::function<void (const Buffer &data)> &code) {
    struct Header {
        openvpn::IPv4Header ip4;
        openvpn::UDPHeader udp;
    } orc_packed;

    // XXX: use scatter gather for this packet
    Beam beam(sizeof(Header) + data.size());
    auto span(beam.span());
    auto &header(span.cast<Header>(0));
    span.copy(sizeof(header), data);

    header.ip4.version_len = openvpn::IPv4Header::ver_len(4, sizeof(header.ip4));
    header.ip4.tos = 0;
    header.ip4.tot_len = boost::endian::native_to_big<uint16_t>(span.size());
    header.ip4.id = 0;
    header.ip4.frag_off = 0;
    header.ip4.ttl = 64;
    header.ip4.protocol = openvpn::IPCommon::UDP;
    header.ip4.check = 0;
    header.ip4.saddr = boost::endian::native_to_big(source.Host().to_v4().to_uint());
    header.ip4.daddr = boost::endian::native_to_big(target.Host().to_v4().to_uint());

    header.ip4.check = openvpn::IPChecksum::checksum(span.data(), sizeof(header.ip4));

    header.udp.source = boost::endian::native_to_big(source.Port());
    header.udp.dest = boost::endian::native_to_big(target.Port());
    header.udp.len = boost::endian::native_to_big<uint16_t>(sizeof(openvpn::UDPHeader) + data.size());
    header.udp.check = 0;

    header.udp.check = boost::endian::native_to_big(openvpn::udp_checksum(
        reinterpret_cast<uint8_t *>(&header.udp),
        boost::endian::big_to_native(header.udp.len),
        reinterpret_cast<uint8_t *>(&header.ip4.saddr),
        reinterpret_cast<uint8_t *>(&header.ip4.daddr)
    ));

    return code(std::move(beam));
}

}
