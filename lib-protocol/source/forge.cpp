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


#include "forge.hpp"

namespace orc {

uint32_t ForgeIP4(Span<> &span, uint32_t (openvpn::IPv4Header::*field), uint32_t value) {
    auto &ip4(span.cast<openvpn::IPv4Header>());
    auto before(boost::endian::big_to_native(ip4.*field));
    ip4.*field = boost::endian::native_to_big(value);

    auto adjust((int32_t(before >> 16) + int32_t(before & 0xffff)) - (int32_t(value >> 16) + int32_t(value & 0xffff)));
    Forge(ip4, adjust);

    auto length(openvpn::IPv4Header::length(ip4.version_len));
    orc_assert(span.size() >= length);

#if 0
    auto check(ip4.check);
    ip4.check = 0;
    orc_insist(openvpn::IPChecksum::checksum(span.data(), length) == check);
    ip4.check = check;
#endif

    switch (ip4.protocol) {
        case openvpn::IPCommon::TCP:
            Forge(span.cast<openvpn::TCPHeader>(length), adjust);
            break;
        case openvpn::IPCommon::UDP:
            Forge(span.cast<openvpn::UDPHeader>(length), adjust);
            break;
        case openvpn::IPCommon::ICMPv4:
            break;
        default:
            orc_assert(false);
    }

    return before;
}

}
