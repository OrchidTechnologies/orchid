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


#include "port.hpp"
#include "protect.hpp"
#include "log.hpp"

#include <netinet/in.h>


namespace orc {

bool vpn_protect(int s);

int Protect(int socket, int (*attach)(int, const sockaddr *, socklen_t), const sockaddr *address, socklen_t length) {
    bool is_local = false;
    if (address->sa_family == AF_INET) {
        const struct sockaddr_in *s = reinterpret_cast<const struct sockaddr_in *>(address);
        is_local = (Host(s->sin_addr) == Host_);
    }
    if (!is_local && !vpn_protect(socket))
        return -1;
    return attach(socket, address, length);
}

}
