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

int Protect(int socket, const sockaddr *address, socklen_t length) {
    if (address == nullptr)
        return 0;
    return Bind(socket, address, length);

    std::unique_ptr<ifaddrs, decltype(freeifaddrs) *> interfaces([]() {
        ifaddrs *interfaces;
        orc_assert(getifaddrs(&interfaces) != -1);
        return interfaces;
    }(), &freeifaddrs);

    if (interfaces != nullptr) {
        /*for (ifaddrs *i(interfaces); i != NULL; i = i->ifa_next) {
            NSLog(@ "ifa_name: %u %s", i->ifa_addr->sa_family, i->ifa_name);
            if (i->ifa_addr->sa_family == AF_INET)
                NSLog(@ "addr: %s", inet_ntoa(((sockaddr_in &)(i->ifa_addr)).sin_addr));
        }*/

        for (auto i(interfaces.get()); i != NULL; i = i->ifa_next) {
            if (i->ifa_addr->sa_family == AF_INET && strncmp(i->ifa_name, "en0", 3) == 0) {
                int index(if_nametoindex(i->ifa_name));
                setsockopt(socket, IPPROTO_IP, IP_BOUND_IF, &index, sizeof(index));
                break;
            }
        }
    }
}

}
