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


#ifndef ORCHID_FORGE_HPP
#define ORCHID_FORGE_HPP

#include <openvpn/ip/csum.hpp>
#include <openvpn/ip/icmp4.hpp>
#include <openvpn/ip/ip4.hpp>
#include <openvpn/ip/tcp.hpp>
#include <openvpn/ip/udp.hpp>

#include "buffer.hpp"
#include "socket.hpp"

namespace orc {

// XXX: I can do much better than this

template <typename Header_>
static void Forge(Header_ &header, int adjust) {
    boost::endian::big_to_native_inplace(header.check);
    openvpn::tcp_adjust_checksum(adjust, header.check);
    boost::endian::native_to_big_inplace(header.check);
}

static void Forge(openvpn::ICMPv4 &header, int adjust) {
    boost::endian::big_to_native_inplace(header.checksum);
    openvpn::tcp_adjust_checksum(adjust, header.checksum);
    boost::endian::native_to_big_inplace(header.checksum);
}

template <typename Header_>
uint16_t Forge(Header_ &header, uint16_t (Header_::*field), uint16_t value) {
    auto before(boost::endian::big_to_native(header.*field));
    header.*field = boost::endian::native_to_big(value);
    Forge(header, int32_t(before) - int32_t(value));
    return before;
}

uint32_t ForgeIP4(Span<> &span, uint32_t (openvpn::IPv4Header::*field), uint32_t value);

static void Forge(Span<> &span, openvpn::TCPHeader &tcp, const Socket &source, const Socket &destination) {
    ForgeIP4(span, &openvpn::IPv4Header::saddr, source.Host().operator uint32_t());
    Forge(tcp, &openvpn::TCPHeader::source, source.Port());
    ForgeIP4(span, &openvpn::IPv4Header::daddr, destination.Host().operator uint32_t());
    Forge(tcp, &openvpn::TCPHeader::dest, destination.Port());
}

}

#endif//ORCHID_FORGE_HPP
