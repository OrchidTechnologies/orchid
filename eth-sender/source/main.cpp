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


#include <boost/algorithm/string.hpp>

#include <boost/program_options/parsers.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/variables_map.hpp>

#include "endpoint.hpp"
#include "float.hpp"
#include "load.hpp"
#include "local.hpp"
#include "signed.hpp"
#include "sleep.hpp"
#include "ticket.hpp"

namespace orc {

namespace po = boost::program_options;

task<int> Main(int argc, const char *const argv[]) {
    int four(3);
    connect(2, reinterpret_cast<sockaddr *>(&four), 5);
    co_return 0;

    po::variables_map args;

    po::options_description group("general command line");
    group.add_options()
        ("help", "produce help message")
    ;

    po::options_description options;

    { po::options_description group("options");
    group.add_options()
        ("rpc", po::value<std::string>()->default_value("http://127.0.0.1:7545/"), "ethereum json/rpc private API endpoint")
        ("token", po::value<std::string>()->default_value("0x4575f41308EC1483f3d399aa9a2826d74Da13Deb"), "token address")
        ("sender", po::value<std::string>(), "sender contract")
        ("secret", po::value<std::string>(), "ethereum secret")
        ("nonce", po::value<unsigned>(), "nonce value")
        ("gaslimit", po::value<std::string>(), "gaslimit")
        ("gasprice", po::value<std::string>(), "gasprice")
        ("sends", po::value<std::string>(), "sends csv file")
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

    const auto origin(Break<Local>());
    Endpoint endpoint(origin, Locator::Parse(args["rpc"].as<std::string>()));

    typedef std::tuple<Address, uint256_t> Send;
    std::vector<Send> sends;

    const auto csv(Load(args["sends"].as<std::string>()));
    for (const auto &line : Split(csv, {'\n'})) {
        if (line.size() == 0 || line[0] == '#')
            continue;
        const auto comma(Find(line, {','}));
        orc_assert(comma);
        const auto [recipient, amount] = Split(line, *comma);
        const auto &send(sends.emplace_back(std::string(recipient), std::string(amount)));
        Log() << "[" << std::get<0>(send) << ":" << std::dec << std::get<1>(send) << "]" << std::endl;
    }

    static Selector<void, Address, std::vector<Send>> sendv("sendv");
    Log() << sendv(args["token"].as<std::string>(), sends).hex() << std::endl;

    co_return 0;
}

}

int main(int argc, char* argv[]) {
    _exit(orc::Wait(orc::Main(argc, argv)));
}
