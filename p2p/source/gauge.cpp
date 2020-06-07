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


#include "gauge.hpp"
#include "json.hpp"
#include "locator.hpp"
#include "origin.hpp"

namespace orc {

task<S<std::map<unsigned, double>>> Gauge::Update_(Origin &origin) { try {
    auto result(Parse((co_await origin.Fetch("GET", {"https", "ethgasstation.info", "443", "/json/ethgasAPI.json"}, {}, {})).ok()));

    const auto &range(result["gasPriceRange"]);
    orc_assert(range.isObject());

    auto prices(Make<Prices_>());
    for (const auto &price : range.getMemberNames())
        prices->emplace(To(price), range[price].asDouble() * 60);

    co_return std::move(prices);
} orc_stack({}, "updating gas prices") }

uint256_t Gauge::Price() const {
    return [&]() {
        double maximum(0);
        for (const auto &[price, time] : *(*prices_)())
            if (maximum == 0)
                maximum = time;
            else if (time != maximum)
                return price;
        orc_assert(false);
    }() * Gwei / 10;
}

}
