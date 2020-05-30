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


#include <unistd.h>

#include <boost/filesystem/string_file.hpp>

#include <boost/program_options/parsers.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/variables_map.hpp>

#include "baton.hpp"
#include "capture.hpp"
#include "error.hpp"
#include "log.hpp"
#include "port.hpp"
#include "transport.hpp"
#include "tunnel.hpp"

namespace orc {

namespace po = boost::program_options;

std::string Group() {
    return boost::filesystem::current_path().string();
}

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

    Tunnel(*capture, [&](const std::string &device, const std::string &argument) {
        orc_assert(system(("ifconfig " + device + " inet " + local.String() + " " + local.String() + " mtu 1500 up").c_str()) == 0);

        if (args.count("capture") != 0)
            orc_assert(system(("route -n add " + args["capture"].as<std::string>() + " " + argument + " " + device).c_str()) == 0);
        else {
            // XXX: having a default route causes connect() to fail with "Network is unreachable" (on macOS)
            //orc_assert(system(("route -n add -net 0.0.0.0/1 " + argument + " " + device).c_str()) == 0);
            //orc_assert(system(("route -n add -net 128.0.0.0/1 " + argument + " " + device).c_str()) == 0);

            orc_assert(system(("route -n add -net 1/8 " + argument + " " + device).c_str()) == 0);
            orc_assert(system(("route -n add -net 2/7 " + argument + " " + device).c_str()) == 0);
            orc_assert(system(("route -n add -net 4/6 " + argument + " " + device).c_str()) == 0);
            orc_assert(system(("route -n add -net 8/5 " + argument + " " + device).c_str()) == 0);
            orc_assert(system(("route -n add -net 16/4 " + argument + " " + device).c_str()) == 0);
            orc_assert(system(("route -n add -net 32/3 " + argument + " " + device).c_str()) == 0);
            orc_assert(system(("route -n add -net 64/2 " + argument + " " + device).c_str()) == 0);
            orc_assert(system(("route -n add -net 128/1 " + argument + " " + device).c_str()) == 0);
        }

        orc_assert(system(("route -n add 10.7.0.4 " + argument + " " + device).c_str()) == 0);

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
