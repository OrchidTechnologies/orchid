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


#include <iostream>
#include <regex>
#include <vector>

#include <sys/types.h>
#include <dirent.h>

#include <boost/program_options/parsers.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/variables_map.hpp>

#include "baton.hpp"
#include "format.hpp"
#include "load.hpp"
#include "local.hpp"
#include "notation.hpp"
#include "remote.hpp"
#include "scope.hpp"
#include "site.hpp"
#include "store.hpp"
#include "transport.hpp"
#include "version.hpp"

using boost::multiprecision::uint256_t;

namespace orc {

namespace po = boost::program_options;

std::string Human(unsigned seconds) {
    unsigned minutes(seconds / 60);
    seconds %= 60;
    unsigned hours(minutes / 60);
    minutes %= 60;
    unsigned days(hours / 24);
    hours %= 24;
    std::ostringstream human;
    if (days != 0)
        human << days << "d";
    if (hours != 0)
        human << hours << "h";
    if (minutes != 0)
        human << minutes << "m";
    if (seconds != 0)
        human << seconds << "s";
    return human.str();
}

int Main(int argc, const char *const argv[]) {
    std::vector<std::string> openvpns;
    std::vector<std::string> wireguards;

    po::variables_map args;

    po::options_description group("general command line");
    group.add_options()
        ("help", "produce help message")
    ;

    po::options_description options;

    { po::options_description group("specific command line");
    group.add_options()
        ("port", po::value<uint16_t>()->default_value(443), "port to advertise on blockchain")
        ("tls", po::value<std::string>(), "tls keys and chain (pkcs#12 encoded)")
        ("root", po::value<std::string>(), "root directory of website to share")
    ; options.add(group); }

    po::store(po::parse_command_line(argc, argv, po::options_description()
        .add(group)
        .add(options)
    ), args);

    po::notify(args);

    if (args.count("help") != 0) {
        std::cout << po::options_description()
            .add(group)
            .add(options)
        << std::endl;
        return 0;
    }

    Initialize();

    Site site;

    std::map<std::string, std::string> types{
        {"frag", "text/plain"},
        {"html", "text/html"},
        {"js", "text/javascript"},
        {"json", "application/json"},
        {"otf", "application/octet-stream"},
        {"png", "image/png"},
        {"ttf", "application/octet-stream"},
        {"wasm", "application/wasm"},
    };

    const std::string root(args["root"].as<std::string>());

    site(http::verb::get, "(/(?:[_a-zA-Z0-9\\-]+/)*(?:[_a-zA-Z0-9\\-]+\\.)+([a-z]+))(?:\\?.*)?"_ctre, [&](Matches2 matches, Request request) -> task<Response> {
        co_return Respond(request, http::status::ok, {
            {"content-type", types.at(matches.get<2>().str())},
            {"expires", "0"},
        }, Load(F() << root << matches.get<1>().str()));
    });

    site(http::verb::get, "(|/[a-zA-Z0-9/_\\-]*)/"_ctre, [&](Matches1 matches, Request request) -> task<Response> {
        Markup markup("index");
        std::ostringstream body;
        auto dir(opendir((root + matches.get<1>().str()).c_str()));
        orc_assert(dir != nullptr);
        _scope({ closedir(dir); });
        while (auto file = readdir(dir))
            body << "<a href='" << Escape(file->d_name) << (file->d_type == DT_DIR ? "/" : "") << "'>" << Escape(file->d_name) << "</a><br/>";
        markup << body.str();
        co_return Respond(request, http::status::ok, {
            {"content-type", "text/html"},
            {"expires", "0"},
        }, markup());
    });

    const Store store(Load(args["tls"].as<std::string>()));
    site.Run(boost::asio::ip::make_address("0.0.0.0"), args["port"].as<uint16_t>(), store.Key(), store.Certificates());
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
