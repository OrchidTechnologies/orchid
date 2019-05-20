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

#include "baton.hpp"
#include "channel.hpp"
#include "client.hpp"
#include "crypto.hpp"
#include "error.hpp"
//#include "ethereum.hpp"
#include "jsonrpc.hpp"
#include "task.hpp"
#include "trace.hpp"

#include <boost/multiprecision/cpp_int.hpp>

using boost::multiprecision::uint256_t;

namespace orc {
int Main() {
    cppcoro::async_manual_reset_event block;

    //Ethereum();

    /*Wait([&]() -> task<void> {
        boost::asio::system_timer timer(Context());
        timer.expires_after(std::chrono::seconds(3));
        co_await timer.async_wait(Token());
        std::cerr << "WOOT" << std::endl;
        timer.expires_after(std::chrono::seconds(3));
        co_await timer.async_wait(Token());
        std::cerr << "WOOT" << std::endl;
    }());*/

    return Wait([&]() -> task<int> {
        co_await Schedule();

        //Log() << co_await GetLocal()->Request("GET", {"http", "cydia.saurik.com", "80", "/debug.txt"}, {}, "") << std::endl;
        //co_return 0;

        //Endpoint endpoint({"http", "localhost", "8545", "/"});
        //Endpoint endpoint({"https", "mainnet.infura.io", "443", "/v3/" ORCHID_INFURA});
        /*Endpoint endpoint({"https", "eth-mainnet.alchemyapi.io", "443", "/jsonrpc/" ORCHID_ALCHEMY});
        std::string storage(co_await endpoint("eth_getStorageAt", {"0x295a70b2de5e3953354a6a8344e616ed314d7251", "0x6661e9d6d8b923d5bbaab1b96e1dd51ff6ea2a93520fdc9eb75d059238b8c5e9", "0x65a8db"}));
        uint256_t parsed(storage);
        Log() << parsed << std::endl;
        co_return 0;*/

        class Watch :
            public Pipe,
            public BufferDrain
        {
          protected:
            virtual Link *Inner() = 0;

            void Land(const Buffer &data) override {
                Log() << "Land" << data << std::endl;
            }

            void Stop(const std::string &error) override {
                Log() << "Stop(" << error << ")" << std::endl;
            }

          public:
            task<void> Send(const Buffer &data) override {
                co_return co_await Inner()->Send(data);
            }
        };

        Sink<Watch> watch;

        auto origin(co_await Setup());
        co_await origin->Connect(&watch, "127.0.0.1", "9999");

        co_await watch.Send(Beam("test\n"));

        co_await block;

        /*co_await service->Connect("cydia.saurik.com", "80");

        for (;;) {
            sleep(3);
            co_await service->Connect("cydia.saurik.com", "80");
        }*/

        co_return 0;
    }());
} }

int main() {
    return orc::Main();
}
