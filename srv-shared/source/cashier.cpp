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


#include <boost/multiprecision/cpp_bin_float.hpp>

#include <cppcoro/async_manual_reset_event.hpp>

#include "baton.hpp"
#include "cashier.hpp"

namespace orc {

task<void> Cashier::Update(cpp_dec_float_50 price, const std::string &currency) {
    price /= co_await Price("ETH", currency) / 200;
    price *= 1000000000;
    price /= 1024 * 1024 * 1024;
    price *= 1000000000;

    std::unique_lock<std::mutex> lock(mutex_);
    using boost::multiprecision::cpp_bin_float_quad;
    price_ = static_cast<uint256_t>(static_cast<cpp_bin_float_quad>(price) * static_cast<cpp_bin_float_quad>(uint256_t(1) << 128));
}

Cashier::Cashier(Endpoint endpoint, Address lottery, const std::string &price, const std::string &currency, Address personal, std::string password, Address recipient) :
    endpoint_(std::move(endpoint)),
    lottery_(std::move(lottery)),
    personal_(std::move(personal)),
    password_(std::move(password)),
    recipient_(std::move(recipient))
{
    cppcoro::async_manual_reset_event ready;

    Spawn([&ready, this, price = cpp_dec_float_50(price), currency]() -> task<void> {
        co_await Update(price, currency);
        ready.set();
        for (;;) {
            boost::asio::deadline_timer timer(Context(), boost::posix_time::minutes(5));
            co_await timer.async_wait(Token());
            co_await Update(price, currency);
        }
    });

    Wait([&]() -> task<void> {
        co_await ready;
    }());
}

}
