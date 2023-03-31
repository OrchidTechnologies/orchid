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


#include "chain.hpp"
#include "locator.hpp"
#include "market.hpp"
#include "parallel.hpp"
#include "pricing.hpp"
#include "sequence.hpp"
#include "updater.hpp"

namespace orc {

task<Market> Market::New(unsigned milliseconds, S<Chain> chain, Currency currency) {
    auto bid(co_await Opened(Updating(milliseconds, [chain]() -> task<uint256_t> {
        co_return co_await chain->Bid(); }, "Bid")));
    co_return Market{std::move(chain), std::move(currency), std::move(bid)};
}

task<Market> Market::New(unsigned milliseconds, const S<Ethereum> &ethereum, const S<Base> &base, uint256_t chain, std::string currency, Locator locator) {
    auto [chain$, currency$] = *co_await Parallel(Chain::New({std::move(locator), base}, {}, chain), Currency::New(milliseconds, ethereum, base, std::move(currency)));
    co_return co_await New(milliseconds, std::move(chain$), std::move(currency$));
}

task<std::set<Market, std::less<>>> Market::All(unsigned milliseconds, const S<Ethereum> &ethereum, const S<Base> &base, const std::vector<std::string> &chains) {
    std::set<Market, std::less<>> markets;
    *co_await Parallel(Map([&](const std::string &market) -> task<void> {
        const auto [chain, currency, locator] = Split<3>(market, {','});
        markets.emplace(co_await New(milliseconds, ethereum, base, uint256_t(chain.operator std::string()), currency.operator std::string(), locator.operator std::string()));
    }, chains));
    co_return markets;
}

}
