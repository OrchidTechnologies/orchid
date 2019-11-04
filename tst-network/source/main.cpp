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
#include "server.hpp"
#include "crypto.hpp"
#include "error.hpp"
#include "jsonrpc.hpp"
#include "task.hpp"
#include "trace.hpp"

#include <boost/multiprecision/cpp_int.hpp>

using boost::multiprecision::uint256_t;

namespace orc {
int Main(int argc, const char *const argv[]) {
    orc_assert(argc == 3);
    std::string host(argv[1]);
    std::string port(argv[2]);

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

        class Watch :
            public Pipe,
            public BufferDrain
        {
          private:
            std::string error_;
            cppcoro::async_manual_reset_event done_;

          protected:
            virtual Link *Inner() = 0;

            void Land(const Buffer &data) override {
                Log() << "Land" << data << std::endl;
            }

            void Stop(const std::string &error) override {
                Log() << "Stop(" << error << ")" << std::endl;
                error_ = error;
                done_.set();
            }

          public:
            task<void> Send(const Buffer &data) override {
                co_return co_await Inner()->Send(data);
            }

            task<void> Done() {
                co_await done_;
                orc_assert_(error_.empty(), error_);
            }
        };

        Sink<Watch> watch;

        auto origin(co_await Setup());
        co_await origin->Connect(&watch, host, port);

        co_await watch.Send(Beam("test\n"));

        co_await watch.Done();
        co_return 0;
    }());
} }

int main(int argc, const char *const argv[]) { try {
    return orc::Main(argc, argv);
} catch (const std::exception &error) {
    std::cerr << error.what() << std::endl;
    return 1;
} }
