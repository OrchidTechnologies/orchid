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


#include <iostream>
#include <vector>

#include "dns.hpp"
#include "coinbase.hpp"
#include "client.hpp"
#include "crypto.hpp"
#include "jsonrpc.hpp"
#include "local.hpp"
#include "network.hpp"
#include "remote.hpp"
#include "sleep.hpp"
#include "trace.hpp"

#include <boost/multiprecision/cpp_int.hpp>

#include <boost/program_options/parsers.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/variables_map.hpp>

#include <rtc_base/logging.h>

using boost::multiprecision::uint256_t;

namespace orc {

namespace po = boost::program_options;

static const Float Ten18("1000000000000000000");
static const Float Two128(uint256_t(1) << 128);

task<std::string> Test(const S<Origin> &origin, const Float &price, Network &network, std::string provider, std::string name, const Secret &secret, const Address &funder, const Address &seller) {
    try {
        std::cout << provider << " " << name << std::endl;
        auto remote(Break<Sink<Remote>>());
        const auto client(co_await network.Select(remote.get(), origin, "untrusted.orch1d.eth", provider, "0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1", 1, secret, funder, seller));
        remote->Open();
        const auto body((co_await remote->Request("GET", {"https", "cache.saurik.com", "443", "/orchid/test-1MB.dat"}, {}, {})).ok());
        client->Update();
        co_await Sleep(3);
        const auto balance(client->Balance());
        const auto spent(client->Spent());
        const auto cost(Float(spent - balance) / body.size() * (1024 * 1024 * 1024) * price / Two128);
        std::ostringstream string;
        string << cost;
        Log() << "\e[32m[" << name << "] " << string.str() << "\e[0m" << std::endl;
        co_return string.str();
    } catch (const std::exception &error) {
        Log() << "\e[32m[" << name << "] " << error.what() << "\e[0m" << std::endl;
        co_return error.what();
    }
}

extern double WinRatio_;

// NOLINTNEXTLINE (modernize-avoid-c-arrays)
int Main(int argc, const char *const argv[]) {
    po::variables_map args;

    po::options_description options("command-line (only)");
    options.add_options()
        ("help", "produce help message")
        ("funder", po::value<std::string>())
        ("secret", po::value<std::string>())
        ("seller", po::value<std::string>()->default_value("0x0000000000000000000000000000000000000000"))
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

    const std::string rpc("https://cloudflare-eth.com:443/");

    const Address directory("0x918101FB64f467414e9a785aF9566ae69C3e22C5");
    const Address location("0xEF7bc12e0F6B02fE2cb86Aa659FdC3EBB727E0eD");

    const Address funder(args["funder"].as<std::string>());
    const Secret secret(Bless(args["secret"].as<std::string>()));
    const Address seller(args["seller"].as<std::string>());

    return Wait([&]() -> task<int> {
        co_await Schedule();

        const auto origin(Break<Local>());

        const auto price(co_await Price(*origin, "OXT", "USD", Ten18));
        Network network(rpc, directory, location);

        for (;;) {
            std::vector<std::string> names;
            std::vector<task<std::string>> tests;

            // NOLINTNEXTLINE (modernize-avoid-c-arrays)
            for (const auto &[provider, name] : (std::pair<const char *, const char *>[]) {
                {"0xe675657B3fBbe12748C7A130373B55c898E0Ea34", "BolehVPN"},
                {"0xf885C3812DE5AD7B3F7222fF4E4e4201c7c7Bd4f", "LiquidVPN"},
                {"0x40e7cA02BA1672dDB1F90881A89145AC3AC5b569", "VPNSecure"},
                {"0x396bea12391ac32c9b12fdb6cffeca055db1d46d", "Tenta"},
            }) {
                names.emplace_back(name);
                tests.emplace_back(Test(origin, price, network, provider, name, secret, funder, seller));
            }

            const auto costs(co_await cppcoro::when_all(std::move(tests)));

            std::cout << std::endl;
            for (unsigned i(0); i != names.size(); ++i)
                std::cout << "\e[32m[" << names[i] << "] " << costs[i] << "\e[0m" << std::endl;
            _exit(0);
        }

        co_return 0;
    }());
}

}

int main(int argc, const char *const argv[]) { try {
    return orc::Main(argc, argv);
} catch (const std::exception &error) {
    std::cerr << error.what() << std::endl;
    return 1;
} }
