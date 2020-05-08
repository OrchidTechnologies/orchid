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

#include <rtc_base/logging.h>

using boost::multiprecision::uint256_t;

namespace orc {

static const Float Ten18("1000000000000000000");
static const Float Two128(uint256_t(1) << 128);

task<std::string> Test(const S<Origin> &origin, const Float &price, Network &network, std::string provider, std::string name, const Secret &secret, const std::string &funder) {
    try {
        std::cout << provider << " " << name << std::endl;
        auto remote(Break<Sink<Remote>>());
        const auto client(co_await network.Select(remote.get(), origin, "untrusted.orch1d.eth", provider, "0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1", 1, secret, funder));
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
    orc_assert(argc == 1);
    //WinRatio_ = 10;

    const std::string rpc("http://localhost:8545/");

    const Secret secret(Bless("d3b7d9e431efff753769bbcf727a00a0b3c6d3e2f62d322e6b3ea6b256ca651c"));
    const std::string funder("0x2b1ce95573ec1b927a90cb488db113b40eeb064a");

    const Address directory("0x918101FB64f467414e9a785aF9566ae69C3e22C5");
    const Address location("0xEF7bc12e0F6B02fE2cb86Aa659FdC3EBB727E0eD");

    return Wait([&]() -> task<int> {
        co_await Schedule();

        const auto origin(Break<Local>());

        //for (;;) (void) co_await Resolve(*origin, "www.saurik.com", "80");

        const auto price(co_await Price(*origin, "OXT", "USD", Ten18));
        Network network(rpc, directory, location);

        for (;;) {
            std::vector<task<std::string>> tests;

            // NOLINTNEXTLINE (modernize-avoid-c-arrays)
            for (const auto &[provider, name] : (std::pair<const char *, const char *>[]) {
                //{"0xe675657B3fBbe12748C7A130373B55c898E0Ea34", "bolehvpn"},
                //{"0xf885C3812DE5AD7B3F7222fF4E4e4201c7c7Bd4f", "liquidvpn"},
                {"0x40e7cA02BA1672dDB1F90881A89145AC3AC5b569", "vpnsecure"},
                //{"0x396bea12391ac32c9b12fdb6cffeca055db1d46d", "tenta"},
            }) {
                tests.emplace_back(Test(origin, price, network, provider, name, secret, funder));
            }

            co_await cppcoro::when_all(std::move(tests));
            _trace();
            co_await Sleep(120);
        }

        co_return 0;
    }());
}

}

int main(int argc, const char *const argv[]) { try {
    rtc::LogMessage::LogToDebug(rtc::LS_INFO);
    return orc::Main(argc, argv);
} catch (const std::exception &error) {
    std::cerr << error.what() << std::endl;
    return 1;
} }
