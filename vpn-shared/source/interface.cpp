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


#ifdef _WIN32
#include <ws2tcpip.h>
#else
#include <netinet/in.h>
#endif

#include "log.hpp"
#include "protect.hpp"
#include "syscall.hpp"

namespace orc {

extern "C" decltype(system_bind) hooked_bind __asm__(ORC_SYMBOL "bind");

extern "C" decltype(system_connect) hooked_connect __asm__(ORC_SYMBOL "connect");

extern "C" int orchid_bind(SOCKET socket, const struct sockaddr *address, socklen_t length) {
    if (Verbose) {
        Log() << "bind(" << socket << ", " << length << ")" << std::endl;
        Log() << "Protect(" << socket << ")" << std::endl;
    }

    return Protect(socket, &hooked_bind, address, length);
}

extern "C" int orchid_connect(SOCKET socket, const struct sockaddr *address, socklen_t length) {
    if (Verbose)
        Log() << "connect(" << socket << ", " << length << ")" << std::endl;

    union {
        sockaddr sa;
        sockaddr_in in;
        sockaddr_in6 in6;
    } data;

    socklen_t size(sizeof(data));
#ifdef _WIN32
    if (orc_syscall(getsockname(socket, &data.sa, &size), WSAEINVAL) != 0)
        size = 0;
#else
    if (orc_syscall(getsockname(socket, &data.sa, &size), EOPNOTSUPP) != 0)
        goto connect;
#endif
    if (size == 0 || [&]() { switch (data.sa.sa_family) {
        case AF_INET:
            return data.in.sin_port == 0;
        case AF_INET6:
            return data.in6.sin6_port == 0;
        default:
            return false;
    } }()) {
        if (Verbose)
            Log() << "Protect(" << socket << ")" << std::endl;
        return Protect(socket, &hooked_connect, address, length);
    }

#ifndef _WIN32
  connect:
#endif
    return hooked_connect(socket, address, length);
}

}
