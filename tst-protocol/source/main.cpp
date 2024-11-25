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
#include <system_wrappers/include/field_trial.h>

#include "baton.hpp"
#include "boring.hpp"
#include "chainlink.hpp"
#include "chart.hpp"
#include "client0.hpp"
#include "client1.hpp"
#include "crypto.hpp"
#include "currency.hpp"
#include "dns.hpp"
#include "float.hpp"
#include "fiat.hpp"
#include "jsonrpc.hpp"
#include "load.hpp"
#include "local.hpp"
#include "main.hpp"
#include "notation.hpp"
#include "oracle.hpp"
#include "pile.hpp"
#include "pricing.hpp"
#include "remote.hpp"
#include "sleep.hpp"
#include "store.hpp"
#include "time.hpp"
#include "transport.hpp"
#include "uniswap.hpp"
#include "updater.hpp"
#include "version.hpp"

using boost::multiprecision::uint256_t;

namespace orc {

namespace po = boost::program_options;

struct Report {
    Address stakee_;
    std::optional<Float> cost_;
    Float speed_;
    Host host_;
    Address recipient_;
};

struct State {
    uint256_t timestamp_;
    Float speed_;
    std::map<std::string, Maybe<Report>> providers_;

    State(uint256_t timestamp) :
        timestamp_(std::move(timestamp))
    {
    }
};

template <typename Type_, typename Value_>
auto &At(Type_ &&type, const Value_ &value) {
    auto i(type.find(value));
    orc_assert(i != type.end());
    return *i;
}

task<int> Main(int argc, const char *const argv[]) {
    std::vector<std::string> chains;

    po::variables_map args;

    po::options_description group("general command line");
    group.add_options()
        ("help", "produce help message")
    ;

    po::options_description options;

    { po::options_description group("orchid account");
    group.add_options()
        ("funder", po::value<std::string>())
        ("secret", po::value<std::string>())
    ; options.add(group); }

    { po::options_description group("evm json/rpc server (required)");
    group.add_options()
        ("chain", po::value<std::vector<std::string>>(&chains), "like 1,ETH,https://cloudflare-eth.com/")
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
        co_return 0;
    }

    Initialize();

    const unsigned milliseconds(60*1000);
    const S<Base> base(Break<Local>());

    const auto ethereum(Wait(Ethereum::New(base, chains)));
    const auto markets(Wait(Market::All(milliseconds, ethereum, base, chains)));

    static const Address lottery0("0xb02396f06cc894834b7934ecf8c8e5ab5c1d12f1");
    static const Address lottery1("0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82");

    const Address funder(args["funder"].as<std::string>());
    const auto secret(Bless<Secret>(args["secret"].as<std::string>()));

    const auto oracle(Wait(Oracle(milliseconds, ethereum)));
    const auto oxt(Wait(Token::OXT(milliseconds, ethereum)));

    const Locator locator{{"https", "localhost", "8443"}, "/"};

    co_return co_await Using<BufferSink<Remote>>([&](BufferSink<Remote> &remote) -> task<int> {
        Client &client(co_await Client0::Wire(remote, oracle, oxt, lottery0, secret, funder));
        //Client &client(co_await Client1::Wire(remote, oracle, At(markets, 43114), lottery1, secret, funder));

        co_await client.Open(base, locator);
        remote.Open();

        std::cout << Str(Parse((co_await remote.Fetch("GET", {{"https", "cydia.saurik.com", "443"}, "/debug.json"}, {}, {})).ok()).at("host")) << std::endl;
        co_return 0;
    });
}

}
