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


#include <memory>

#include "protect.hpp"

#include <sys/types.h>
#include <sys/socket.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include "error.hpp"
#include "trace.hpp"

namespace orc {

int Protect(int socket, int (*attach)(int, const sockaddr *, socklen_t), const sockaddr *address, socklen_t length) {
    std::unique_ptr<ifaddrs, decltype(freeifaddrs) *> interfaces([]() {
        ifaddrs *interfaces;
        orc_assert(getifaddrs(&interfaces) != -1);
        return interfaces;
    }(), &freeifaddrs);

    if (interfaces != nullptr) {
#if 0
        for (ifaddrs *i(interfaces.get()); i != NULL; i = i->ifa_next) {
            Log() << "ifa_name: " << unsigned(i->ifa_addr->sa_family) << " " << i->ifa_name << std::endl;
            if (i->ifa_addr->sa_family == AF_INET)
                Log() << "addr: " << inet_ntoa(reinterpret_cast<sockaddr_in *>(i->ifa_addr)->sin_addr) << std::endl;
        }
#endif

        if (address->sa_family == AF_INET) {
            const auto address4(reinterpret_cast<const sockaddr_in *>(address));
            for (auto i(interfaces.get()); i != NULL; i = i->ifa_next)
                if (i->ifa_addr->sa_family == AF_INET)
                    if (reinterpret_cast<sockaddr_in *>(i->ifa_addr)->sin_addr.s_addr == address4->sin_addr.s_addr) {
                        const auto index(if_nametoindex(i->ifa_name));
                        setsockopt(socket, IPPROTO_IP, IP_BOUND_IF, &index, sizeof(index));
                        goto done;
                    }
        }

        for (auto i(interfaces.get()); i != NULL; i = i->ifa_next) {
            if (i->ifa_addr->sa_family == AF_INET && strncmp(i->ifa_name, "en0", 3) == 0) {
                const auto index(if_nametoindex(i->ifa_name));
                setsockopt(socket, IPPROTO_IP, IP_BOUND_IF, &index, sizeof(index));
                goto done;
            }
        }
    }

  done:
    return attach(socket, address, length);
}

}
