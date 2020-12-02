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


#include "binance.hpp"
#include "chain.hpp"
#include "locator.hpp"
#include "market.hpp"
#include "parallel.hpp"
#include "updater.hpp"

namespace orc {

task<Market> Market::New(unsigned milliseconds, S<Chain> chain, Currency currency) {
    auto bid(co_await Opened(Updating(milliseconds, [chain]() -> task<uint256_t> {
        co_return co_await chain->Bid(); }, "Bid")));
    co_return Market{std::move(chain), std::move(currency), std::move(bid)};
}

task<Market> Market::New(unsigned milliseconds, uint256_t chain, const S<Origin> &origin, Locator locator, std::string currency) {
    auto [chain$, currency$] = *co_await Parallel(Chain::New({std::move(locator), origin}, {}, chain), Binance(milliseconds, origin, std::move(currency)));
    co_return co_await New(milliseconds, std::move(chain$), std::move(currency$));
}

}
