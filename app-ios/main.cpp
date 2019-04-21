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


#include <condition_variable>
#include <cstdio>
#include <iostream>
#include <memory>
#include <mutex>
#include <thread>
#include <vector>

#include <unistd.h>

#include <cppcoro/sync_wait.hpp>

#include "channel.hpp"
#include "client.hpp"
#include "crypto.hpp"
#include "error.hpp"
//#include "ethereum.hpp"
#include "jsonrpc.hpp"
#include "scope.hpp"
#include "shared.hpp"
#include "task.hpp"
#include "trace.hpp"

#include <boost/multiprecision/cpp_int.hpp>

using boost::multiprecision::uint256_t;

int main() {
    cppcoro::async_manual_reset_event block;

    //orc::Ethereum();

    return orc::Wait([&]() -> task<int> {
        co_await orc::Schedule();

        //orc::Log() << co_await orc::GetLocal()->Request("GET", {"http", "cydia.saurik.com", "80", "/debug.txt"}, {}, "") << std::endl;
        //co_return 0;

        //orc::Endpoint endpoint({"http", "localhost", "8545", "/"});
        //orc::Endpoint endpoint({"https", "mainnet.infura.io", "443", "/v3/" ORCHID_INFURA});
        /*orc::Endpoint endpoint({"https", "eth-mainnet.alchemyapi.io", "443", "/jsonrpc/" ORCHID_ALCHEMY});
        std::string storage(co_await endpoint("eth_getStorageAt", {"0x295a70b2de5e3953354a6a8344e616ed314d7251", "0x6661e9d6d8b923d5bbaab1b96e1dd51ff6ea2a93520fdc9eb75d059238b8c5e9", "0x65a8db"}));
        uint256_t parsed(storage);
        orc::Log() << parsed << std::endl;
        co_return 0;*/

        auto delayed(co_await orc::Setup());
        orc::Sink sink([](const orc::Buffer &data) {
            orc::Log() << data << std::endl;
        }, std::move(delayed.link_));

        co_await delayed.code_("localhost", "9999");
        co_await sink.Send(orc::Beam("test\n"));

        co_await block;

        /*co_await service->Connect("cydia.saurik.com", "80");

        for (;;) {
            sleep(3);
            co_await service->Connect("cydia.saurik.com", "80");
        }*/

        co_return 0;
    }());
}
