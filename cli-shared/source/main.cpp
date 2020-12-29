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
#include "log.hpp"
#include "port.hpp"
#include "protect.hpp"
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
    const auto capture(Break<BufferSink<Capture>>(local));

    Tunnel(*capture, "", [&](const std::string &device, const std::string &argument) {
        setTunIface(device);
#ifdef _WIN32
        orc_assert(system(("netsh interface ip set address \"" + device + "\" static " + local.String() + " 255.255.255.0").c_str()) == 0);
        orc_assert(system(("netsh interface ip set subinterface \"" + device + "\" mtu=1100").c_str()) == 0);
        orc_assert(system(("netsh interface ipv4 set interface \"" + device + "\" metric=0").c_str()) == 0);

        if (args.count("capture") != 0)
            orc_assert(system(("netsh interface ipv4 add route " + args["capture"].as<std::string>() + " " + argument + "/32 \"" + device + "\"").c_str()) == 0);
        else
            orc_assert(system(("netsh interface ipv4 add route 0.0.0.0/0 \"" + device + "\" 10.7.0.4 metric=0").c_str()) == 0);
#else
        orc_assert(system(("ifconfig " + device + " inet " + local.String() + " " + local.String() + " mtu 1100 up").c_str()) == 0);

        if (args.count("capture") != 0)
            orc_assert(system(("route -n add " + args["capture"].as<std::string>() + " " + argument + " " + device).c_str()) == 0);
        else
            // XXX: having a 0.0.0.0/* route causes connect() to fail with "Network is unreachable" on macOS
            //orc_assert(system(("route -n add -net 0.0.0.0/1 " + argument + " " + device).c_str()) == 0);
            //orc_assert(system(("route -n add -net 128.0.0.0/1 " + argument + " " + device).c_str()) == 0);
        for (unsigned i(0); i != 8; ++i) {
            std::ostringstream command;
            command << "route -n add -net " << std::to_string(1 << i) << "/" << std::to_string(8 - i) << " " << argument << " " << device;
            orc_assert_(system(command.str().c_str()) == 0, "system(" << command.str() << ")");
        }

        orc_assert(system(("route -n add 10.7.0.4 " + argument + " " + device).c_str()) == 0);
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
