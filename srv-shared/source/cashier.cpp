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
#include "json.hpp"
#include "sleep.hpp"

namespace orc {

static Float Two128(uint256_t(1) << 128);
//static Float Two30(1024 * 1024 * 1024);

task<void> Cashier::Update() {
    auto eth(co_await Price("ETH", currency_));
    //auto oxt(co_await Price("OXT", currency_));
    auto oxt(eth / 300);
    //auto predict(Parse(co_await Request("GET", {"https", "ethgasstation.info", "443", "/json/predictTable.json"}, {}, {})));

    std::unique_lock<std::mutex> lock(mutex_);
    eth_ = std::move(eth);
    oxt_ = std::move(oxt);
}

Cashier::Cashier(Endpoint endpoint, const Float &price, std::string currency, Address personal, std::string password, Address lottery, uint256_t chain, Address recipient) :
    endpoint_(std::move(endpoint)),

    price_(std::move(price)),
    currency_(std::move(currency)),

    personal_(std::move(personal)),
    password_(std::move(password)),

    lottery_(std::move(lottery)),
    chain_(std::move(chain)),
    recipient_(std::move(recipient))
{
    cppcoro::async_manual_reset_event ready;

    Spawn([&ready, this]() -> task<void> {
        co_await Update();
        ready.set();
        for (;;) {
            co_await Sleep(5 * 60);
            co_await Update();
        }
    });

    Wait([&]() -> task<void> {
        co_await ready;
    }());
}

Float Cashier::Credit(const uint256_t &now, const uint256_t &start, const uint256_t &until, const uint256_t &amount, const uint256_t &gas) const {
    return Float(amount) * oxt_ / Two128;
}

Float Cashier::Bill(size_t size) const {
    return price_ * size;
}

uint256_t Cashier::Convert(const Float &balance) const {
    return uint256_t(balance / oxt_ * Two128);
}

}
