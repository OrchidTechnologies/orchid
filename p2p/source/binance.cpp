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


#include "base.hpp"
#include "currency.hpp"
#include "pricing.hpp"
#include "updater.hpp"

namespace orc {

task<Float> Binance(Base &base, const std::string &pair, const Float &adjust) { orc_block({
    const auto response(co_await base.Fetch("GET", {{"https", "api.binance.com", "443"}, "/api/v3/avgPrice?symbol=" + pair}, {}, {}));
    const auto result(Parse(response.body()).as_object());
    if (response.result() == http::status::ok)
        co_return Float(Str(result.at("price"))) / adjust;
    else {
        const auto code(Num<int64_t>(result.at("code")));
        const auto msg(Str(result.at("msg")));
        orc_throw(response.result() << "/" << code << ": " << msg);
    }
}, "checking " << pair << " on Binance"); }

task<Currency> Binance(unsigned milliseconds, S<Base> base, std::string currency) {
    auto dollars([updated = co_await Opened(Updating(milliseconds, [base = std::move(base), pair = currency + "USDT"]() -> task<Float> {
        co_return pair == "DAIUSDT" ? 1 / co_await Binance(*base, "USDTDAI", 1 / Ten18) : co_await Binance(*base, pair, Ten18);
    }, "Binance"))]() { return (*updated)(); });

    co_return Currency{std::move(currency), std::move(dollars)};
}

}
