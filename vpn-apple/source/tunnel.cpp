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


#include <sys/sys_domain.h>
#include <sys/kern_control.h>
#include <net/if_utun.h>

#include <boost/algorithm/string/predicate.hpp>
#include <boost/asio/generic/datagram_protocol.hpp>

#include "family.hpp"
#include "sync.hpp"
#include "syscall.hpp"
#include "tunnel.hpp"

namespace orc {

void Tunnel(BufferSunk &sunk, const std::string &device, const std::function<void (const std::string &)> &code) {
    auto &family(sunk.Wire<BufferSink<Family>>());
    auto &sync(family.Wire<Sync<asio::generic::datagram_protocol::socket, SyncConnection>>(Context(), asio::generic::datagram_protocol(PF_SYSTEM, SYSPROTO_CONTROL)));
    auto file(sync->native_handle());

    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-member-init)
    ctl_info info;
    memset(&info, 0, sizeof(info));
    orc_assert(strlcpy(info.ctl_name, UTUN_CONTROL_NAME, sizeof(info.ctl_name)) < sizeof(info.ctl_name));
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg)
    orc_syscall(ioctl(file, CTLIOCGINFO, &info));

    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-member-init)
    struct sockaddr_ctl address;
    address.sc_id = info.ctl_id;
    address.sc_len = sizeof(address);
    address.sc_family = AF_SYSTEM;
    address.ss_sysaddr = AF_SYS_CONTROL;

    if (!device.empty()) {
        orc_assert(boost::algorithm::starts_with(device, "utun"));
        address.sc_unit = To<decltype(address.sc_unit)>(device.substr(4));
        orc_syscall(connect(file, reinterpret_cast<struct sockaddr *>(&address), sizeof(address)));
    } else {
        address.sc_unit = 0;
        do ++address.sc_unit;
        while (orc_syscall(connect(file, reinterpret_cast<struct sockaddr *>(&address), sizeof(address)), EBUSY) != 0);
    }

    code("utun" + std::to_string(address.sc_unit - 1));
    sync.Open();
}

}
