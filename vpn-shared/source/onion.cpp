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


#if 0

#include <map>
#include <string>
#include <thread>
#include <vector>

#ifdef __WIN32__
#include <winsock2.h>
#endif

extern "C" {
#include <feature/api/tor_api.h>
}

#include "directory.hpp"
#include "scope.hpp"

namespace orc {

static std::thread thread_;

void Onion() {
    thread_ = std::thread([]() {
        std::vector<std::string> args;
        std::map<std::string, std::string> options;

        options.emplace("SocksPort", "9050");
        options.emplace("DNSPort", "12345");
        options.emplace("DataDirectory", Group() + "/Tor");

        options.emplace("AutomapHostsOnResolve", "1");
        options.emplace("AvoidDiskWrites", "1");
        options.emplace("CookieAuthentication", "1");

        args.emplace_back("--ignore-missing-torrc");

        for (const auto &[key, value] : options) {
            args.emplace_back("--" + key);
            args.emplace_back(value);
        }

        std::vector<char *> argv;
        for (auto &arg : args)
            argv.emplace_back(&arg[0]);
        argv.emplace_back(nullptr);

        std::unique_ptr<tor_main_configuration_t, decltype(tor_main_configuration_free) *> configuration(tor_main_configuration_new(), &tor_main_configuration_free);
        tor_main_configuration_set_command_line(configuration.get(), argv.size() - 1, argv.data());
        tor_run_main(configuration.get());
    });
}

}

#endif
