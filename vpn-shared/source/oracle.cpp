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


#include "chainlink.hpp"
#include "oracle.hpp"
#include "parallel.hpp"
#include "updater.hpp"

namespace orc {

static const Float Ten5("100000");

task<S<Updated<Prices>>> Oracle(unsigned milliseconds, S<Chain> chain) {
    co_return co_await Opened(Updating(milliseconds, [chain = std::move(chain)]() -> task<Prices> {
        const auto [gb1, oxt, xau] = *co_await Parallel(
            Chainlink(*chain, "0x8bD3feF1abb94E6587fCC2C5Cb0931099D0893A0", 0.06, Ten5),
            Chainlink(*chain, ChainlinkOXTUSD, 0.30, Ten8 * Ten18),
            Chainlink(*chain, "0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6", 1800, Ten8 * Ten18)
        );

        // XXX: our Chainlink aggregation can have its answer forged by either Chainlink swapping the oracle set
        //      or by Orchid modifying the backend from our dashboard that Chainlink pays its oracles to consult
        co_return Prices{gb1, oxt > 0.10 ? 0.10 : oxt, xau};
    }, "Oracle"));
}

}
