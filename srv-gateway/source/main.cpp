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

#include <cppcoro/async_mutex.hpp>

#include <boost/program_options/parsers.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/variables_map.hpp>

#include <rtc_base/logging.h>

#include "baton.hpp"
#include "boring.hpp"
#include "chainlink.hpp"
#include "chart.hpp"
#include "crypto.hpp"
#include "dns.hpp"
#include "float.hpp"
#include "fiat.hpp"
#include "jsonrpc.hpp"
#include "load.hpp"
#include "local.hpp"
#include "locator.hpp"
#include "markup.hpp"
#include "notation.hpp"
#include "pricing.hpp"
#include "remote.hpp"
#include "site.hpp"
#include "sleep.hpp"
#include "store.hpp"
#include "time.hpp"
#include "transport.hpp"
#include "uniswap.hpp"
#include "version.hpp"

using boost::multiprecision::uint256_t;

namespace orc {

namespace po = boost::program_options;

int Main(int argc, const char *const argv[]) {
    po::variables_map args;

    po::options_description group("general command line");
    group.add_options()
        ("help", "produce help message")
    ;

    po::options_description options;

    { po::options_description group("network endpoint");
    group.add_options()
        ("port", po::value<uint16_t>()->default_value(8443), "port to listen for the thing")
        ("tls", po::value<std::string>(), "tls keys and chain (pkcs#12 encoded)")
    ; options.add(group); }

    { po::options_description group("orchid account");
    group.add_options()
        ("funder", po::value<std::string>())
        ("secret", po::value<std::string>())
    ; options.add(group); }

    { po::options_description group("external resources");
    group.add_options()
        ("rpc", po::value<std::string>()->default_value("http://127.0.0.1:8545/"), "ethereum json/rpc private API endpoint")
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

    const S<Base> base(Break<Local>());
    const Locator locator(args["rpc"].as<std::string>());

    Site site;

    site(http::verb::post, "/"_ctre, [&](Matches0 matches, Request request) -> task<Response> {
        const auto body(request.body());
        const auto parsed(Parse(body));
#if 0
        co_return Respond(request, http::status::payment_required, {
            {"content-type", "application/json"},
        }, "{}");
#else
        const auto response((co_await base->Fetch("POST", locator, {{"content-type", "application/json"}}, body)).ok());
        co_return Respond(request, http::status::ok, {
            {"content-type", "application/json"},
        }, response);
#endif
    });

    site(http::verb::get, "/version.txt", [&](Request request) -> task<Response> {
        co_return Respond(request, http::status::ok, {
            {"content-type", "text/plain"},
        }, std::string(VersionData, VersionSize));
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
