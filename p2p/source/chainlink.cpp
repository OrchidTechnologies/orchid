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


#include "chainlink.hpp"
#include "endpoint.hpp"
#include "fiat.hpp"
#include "parallel.hpp"
#include "updater.hpp"

namespace orc {

static const Float Ten8("100000000");

task<Float> Chainlink(const Endpoint &endpoint, const Address &aggregation, const Float &adjust) {
    static const Selector<uint256_t> latestAnswer_("latestAnswer");
    co_return Float(co_await latestAnswer_.Call(endpoint, "latest", aggregation, 90000)) / adjust;
}

task<S<Updated<Fiat>>> ChainlinkFiat(unsigned milliseconds, Endpoint endpoint) {
    co_return co_await Update(milliseconds, [endpoint = std::move(endpoint)]() -> task<Fiat> {
        const auto [eth_usd, oxt_usd] = *co_await Parallel(
            Chainlink(endpoint, "0xF79D6aFBb6dA890132F9D7c355e3015f15F3406F", Ten8),
            Chainlink(endpoint, "0x11eF34572CcaB4c85f0BAf03c36a14e0A9C8C7eA", Ten8));
        co_return Fiat{eth_usd / Ten18, oxt_usd / Ten18};
    }, "Chainlink");
}

}
