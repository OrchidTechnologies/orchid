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


#include <openvpn/ip/ip4.hpp>
#include <openvpn/ip/udp.hpp>

#include "datagram.hpp"

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

}
