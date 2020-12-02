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
#include "chainlink.hpp"
#include "fiat.hpp"
#include "parallel.hpp"
#include "updater.hpp"

namespace orc {

const Address ChainlinkETHUSD("0xF79D6aFBb6dA890132F9D7c355e3015f15F3406F");
const Address ChainlinkOXTUSD("0x11eF34572CcaB4c85f0BAf03c36a14e0A9C8C7eA");

task<Float> Chainlink(const Chain &chain, const Address &pair, const Float &backup, const Float &adjust) { try {
    static const Selector<uint256_t> latestAnswer_("latestAnswer");
    const auto value(Float(co_await latestAnswer_.Call(chain, "latest", pair, 90000)));
    co_return (value == 0 ? backup : value) / adjust;
} orc_catch({
    // XXX: Chainlink oracles seem to each have a killswitch left by the Chainlink team :/
    // I need to characterize the ways this killswitch operates to avoid an eclipse attack
    co_return backup / adjust;
}) }

}
