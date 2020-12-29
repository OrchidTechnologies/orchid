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


#include <linux/if_tun.h>

#include "sync.hpp"
#include "syscall.hpp"
#include "tunnel.hpp"

namespace orc {

void Tunnel(BufferSunk &sunk, const std::string &device, const std::function<void (const std::string &)> &code) {
    // XXX: NOLINTNEXTLINE (cppcoreguidelines-pro-type-vararg)
    auto &sync(sunk.Wire<SyncFile<asio::posix::stream_descriptor>>(Context(), open("/dev/net/tun", O_RDWR)));
    auto file(sync->native_handle());

    struct ifreq request;
    request.ifr_flags = IFF_TUN | IFF_NO_PI;
    strncpy(request.ifr_name, device.c_str(), IFNAMSIZ);
    // XXX: NOLINTNEXTLINE (cppcoreguidelines-pro-type-vararg)
    orc_syscall(ioctl(file, TUNSETIFF, &request));
    code(request.ifr_name);

    sync.Open();
}

}
