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


#include <unistd.h>

#include <boost/filesystem/operations.hpp>

#include <boost/program_options/parsers.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/variables_map.hpp>

#include "baton.hpp"
#include "capture.hpp"
#include "error.hpp"
#include "execute.hpp"
#include "log.hpp"
#include "port.hpp"
#include "transport.hpp"
#include "tunnel.hpp"

namespace orc {

namespace po = boost::program_options;

int Main(int argc, const char *const argv[]) {
    po::variables_map args;

    po::options_description options("command-line (only)");
    options.add_options()
        ("help", "produce help message")
        ("capture", po::value<std::string>(), "single ip address to capture")
        ("config", po::value<std::string>(), "configuration file for client configuration")
    ;

    po::store(po::parse_command_line(argc, argv, po::options_description()
        .add(options)
    ), args);

    po::notify(args);

    if (args.count("help") != 0) {
        std::cout << po::options_description()
            .add(options)
        << std::endl;
        return 0;
    }


    Initialize();


    const auto local(Host_);
    const Host network(local.operator uint32_t() & ~0xff);
    const Host gateway(network.operator uint32_t() | 0x01);

    const auto capture(Break<BufferSink<Capture>>(local));

    Tunnel(*capture, "", [&](const std::string &device) {
        static const unsigned mtu(1100);

#ifdef _WIN32
        Execute("netsh", "interface", "ip", "set", "address", device, "static", local, "255.255.255.0");
        Execute("netsh", "interface", "ip", "set", "subinterface", device, "mtu=" + std::to_string(mtu));
        Execute("netsh", "interface", "ipv4", "set", "interface", device, "metric=0");

        const auto destination(args.count("capture") != 0 ? Host(args["capture"].as<std::string>())/32 : "0.0.0.0/0");
        Execute("netsh", "interface", "ipv4", "add", "route", destination, device, gateway, "metric=0");

        //Execute("netsh", "interface", "ipv4", "add", "route", network, device, "metric=0");
#else
        Execute("ifconfig", device, "inet", local/24,
#ifndef __APPLE__
            "dstaddr",
#endif
        local, "mtu", std::to_string(mtu), "up");

#ifdef __APPLE__
        const auto argument("-interface");
#else
        const auto argument("dev");
#endif

        if (args.count("capture") != 0)
            Execute("route", "-n", "add", Host(args["capture"].as<std::string>()), argument, device);
        else for (unsigned i(0); i != 8; ++i)
            // having a 0.0.0.0/* route causes connect() to fail with "Network is unreachable" on macOS
            Execute("route", "-n", "add" , "-net", std::to_string(1 << i) + ".0.0.0/" + std::to_string(8 - i), argument, device);

        Execute("route", "-n", "add", "-net", network/24, argument, device);
#endif

        capture->Start(args["config"].as<std::string>());
    });

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
