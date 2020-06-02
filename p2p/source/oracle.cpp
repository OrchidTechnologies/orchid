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


#include "coinbase.hpp"
#include "error.hpp"
#include "json.hpp"
#include "locator.hpp"
#include "oracle.hpp"
#include "parallel.hpp"
#include "sleep.hpp"

namespace orc {

static const Float Ten18("1000000000000000000");

task<void> Oracle::UpdateCoin(Origin &origin) { try {
    auto [eth, oxt] = *co_await Parallel(Coinbase(origin, "ETH", currency_, Ten18), Coinbase(origin, "OXT", currency_, Ten18));

    const auto fiat(fiat_());
    fiat->eth_ = std::move(eth);
    fiat->oxt_ = std::move(oxt);
} orc_stack({}, "updating fiat prices") }

task<void> Oracle::UpdateGas(Origin &origin) { try {
    auto result(Parse((co_await origin.Fetch("GET", {"https", "ethgasstation.info", "443", "/json/ethgasAPI.json"}, {}, {})).ok()));

    const auto &range(result["gasPriceRange"]);
    orc_assert(range.isObject());

    S<const Prices_> prices([&]() {
        auto prices(std::make_shared<Prices_>());
        for (const auto &price : range.getMemberNames())
            prices->emplace(To(price), range[price].asDouble() * 60);
        return prices;
    }());

    std::swap(*prices_(), prices);
} orc_stack({}, "updating gas prices") }

Oracle::Oracle(std::string currency) :
    currency_(std::move(currency))
{
}

void Oracle::Open(S<Origin> origin) {
    Wait([&]() -> task<void> {
        *co_await Parallel(UpdateCoin(*origin), UpdateGas(*origin));
    }());

    // XXX: this coroutine leaks after Shut
    Spawn([this, origin = std::move(origin)]() noexcept -> task<void> {
        for (;;) {
            co_await Sleep(5 * 60);
            auto [forex, gas] = co_await Parallel(UpdateCoin(*origin), UpdateGas(*origin));
            orc_ignore({ std::move(forex).result(); });
            orc_ignore({ std::move(gas).result(); });
        }
    });
}

task<void> Oracle::Shut() noexcept {
    orc_insist(false);
}

auto Oracle::Fiat() const -> Fiat_ {
    return *fiat_();
}

uint256_t Oracle::Price() const {
    return [&]() {
        double maximum(0);
        for (const auto &[price, time] : *Prices())
            if (maximum == 0)
                maximum = time;
            else if (time != maximum)
                return price;
        orc_assert(false);
    }() * Gwei / 10;
}

auto Oracle::Prices() const -> S<const Prices_> {
    return *prices_();
}

}
