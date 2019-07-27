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


#define OPENVPN_EXTERN extern

#include "log.hpp"
#define OPENVPN_LOG_STREAM orc::Log()
#include <openvpn/log/logsimple.hpp>

#include <cstdio>
#include <cstdlib>
#include <cstring>

#include <cerrno>
#include <unistd.h>

#include <net/if_utun.h>

#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/sys_domain.h>
#include <sys/kern_control.h>

#include <boost/asio/generic/datagram_protocol.hpp>
#include <boost/filesystem/string_file.hpp>

#include <asio.hpp>
#include "capture.hpp"
#include "connection.hpp"
#include "error.hpp"
#include "protect.hpp"
#include "syscall.hpp"
#include "task.hpp"
#include "transport.hpp"

#if 0
#elif defined(__APPLE__)
#include "family.hpp"
#endif

namespace orc {

int Protect(int socket, const sockaddr *address, socklen_t length) {
    if (address == nullptr)
        return 0;
    return Bind(socket, address, length);
}

int Main(int argc, const char *const argv[]) {
    Initialize();

    std::string ovpn;
    boost::filesystem::load_string_file("../app-ios/resource/PureVPN.ovpn", ovpn);

    std::string username(ORCHID_USERNAME);
    std::string password(ORCHID_PASSWORD);

    std::string local("10.7.0.3");

    auto capture(Make<Sink<Capture>>());

#if 0
#elif defined(__APPLE__)
    auto family(capture->Wire<Sink<Family>>());
    auto connection(family->Wire<Connection<asio::generic::datagram_protocol::socket>>(asio::generic::datagram_protocol(PF_SYSTEM, SYSPROTO_CONTROL)));
    auto file((*connection)->native_handle());

    ctl_info info;
    memset(&info, 0, sizeof(info));
    orc_assert(strlcpy(info.ctl_name, UTUN_CONTROL_NAME, sizeof(info.ctl_name)) < sizeof(info.ctl_name));
    orc_syscall(ioctl(file, CTLIOCGINFO, &info));

    struct sockaddr_ctl address;
    address.sc_id = info.ctl_id;
    address.sc_len = sizeof(address);
    address.sc_family = AF_SYSTEM;
    address.ss_sysaddr = AF_SYS_CONTROL;
    address.sc_unit = 0;

    do ++address.sc_unit;
    while (orc_syscall(connect(file, reinterpret_cast<struct sockaddr *>(&address), sizeof(address)), EBUSY) != 0);

    connection->Start();
#else
#error
#endif

    Wait([&]() -> task<void> {
        co_await Schedule();
        co_await capture->Start(std::move(ovpn), std::move(username), std::move(password));

        auto utun("utun" + std::to_string(address.sc_unit - 1));
        orc_assert(system(("ifconfig " + utun + " inet " + local + " 207.254.46.169 mtu 1500 up").c_str()) == 0);
    }());

    Thread().join();
    return 0;
}

}

int main(int argc, const char *const argv[]) { try {
    return orc::Main(argc, argv);
} catch (const std::exception &error) {
    std::cerr << error.what() << std::endl;
    return 1;
} }
