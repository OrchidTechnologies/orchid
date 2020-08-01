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


#if ORC_TRACE

#include <mutex>

#include <openvpn/ip/ip4.hpp>
#include <openvpn/ip/tcp.hpp>

#include "socket.hpp"
#include "time.hpp"
#include "trace.hpp"

namespace orc {

static std::mutex mutex_;

void Trace(const char *type, bool send, const Buffer &data) { try {
    const auto time(Monotonic());

    Window window(data);

    openvpn::IPv4Header ip4;
    window.Take(&ip4);
    if (openvpn::IPCommon::version(ip4.version_len) != uint8_t(openvpn::IPCommon::IPv4))
        return;

    window.Skip(openvpn::IPv4Header::length(ip4.version_len) - sizeof(ip4));
    switch (ip4.protocol) {
        case openvpn::IPCommon::TCP:
            openvpn::TCPHeader tcp;
            window.Take(&tcp);

            char flags[7] = {
                (tcp.flags & (1 << 5)) == 0 ? '.' : 'U',
                (tcp.flags & (1 << 4)) == 0 ? '.' : 'A',
                (tcp.flags & (1 << 3)) == 0 ? '.' : 'P',
                (tcp.flags & (1 << 2)) == 0 ? '.' : 'R',
                (tcp.flags & (1 << 1)) == 0 ? '.' : 'S',
                (tcp.flags & (1 << 0)) == 0 ? '.' : 'F',
            '\0'};

            std::unique_lock<std::mutex> lock(mutex_);
            std::cerr << "\e[" << (send ? "35mSEND" : "33mRECV") <<
                " " << type << " " << std::dec << time << " [" << flags << "]" <<
                " " << Socket(boost::endian::big_to_native(ip4.saddr), tcp.source) << " > " << Socket(boost::endian::big_to_native(ip4.daddr), tcp.dest) <<
                " " << std::dec << std::setfill('0') << std::setw(10) << tcp.seq << ":" << std::setw(10) << tcp.ack_seq <<
                " " << std::dec << window.size() <<
            "\e[0m" << std::endl;
        break;
    }
} orc_catch({}) }

}

#endif
