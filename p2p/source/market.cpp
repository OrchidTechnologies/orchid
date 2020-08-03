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
#include "fiat.hpp"
#include "gauge.hpp"
#include "market.hpp"

namespace orc {

static const Float Two128(uint256_t(1) << 128);
//static const Float Two30(1024 * 1024 * 1024);

Market::Market(unsigned milliseconds, const S<Origin> &origin, S<Updated<Fiat>> fiat) :
    fiat_(std::move(fiat)),
    gauge_(Make<Gauge>(5*60*1000, origin))
{
}

Float Market::Convert(const checked_int256_t &balance) const {
    return Float(balance) / Two128 * (*fiat_)().oxt_;
}

checked_int256_t Market::Convert(const Float &balance) const {
    return checked_int256_t(balance / (*fiat_)().oxt_ * Two128);
}

std::pair<Float, uint256_t> Market::Credit(const uint256_t &now, const uint256_t &start, const uint128_t &range, const uint128_t &amount, const uint128_t &ratio, const uint256_t &gas) const {
    const auto fiat((*fiat_)());

    const auto base(Float(amount) * fiat.oxt_);
    const auto until(start + range);

    std::pair<Float, uint256_t> credit(0, 10*Gwei);

    const auto prices(gauge_->Prices());
    for (const auto &[price, time] : *prices) {
        const auto when(now + unsigned(time));
        if (when >= until) continue;
        const auto cost(price * Gwei / 10);
        const auto profit((start < when ? base * Float(range - (when - start)) / Float(range) : base) - Float(gas * cost) * fiat.eth_);
        if (profit > std::get<0>(credit))
            credit = {profit, cost};
    }

    credit.first *= Float(ratio + 1) / Two128;
    return credit;
}

}
