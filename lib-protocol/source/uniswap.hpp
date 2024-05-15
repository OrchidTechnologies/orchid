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


#ifndef ORCHID_UNISWAP_HPP
#define ORCHID_UNISWAP_HPP

#include "float.hpp"
#include "task.hpp"

namespace orc {

class Address;
class Chain;

static const Float Ten6("1000000");
static const Float Two96(uint256_t(1) << 96);

extern const Address Uniswap2OXTETH;
extern const Address Uniswap2USDCETH;

extern const Address Uniswap3ETHUSDT;
extern const Address Uniswap3OXTETH;
extern const Address Uniswap3USDCETH;
extern const Address Uniswap3WAVAXETH;

task<Float> Uniswap2(const Chain &chain, const Address &pool, const Float &adjust);
task<Float> Uniswap3(const Chain &chain, const Address &pool, const Float &adjust);

}

#endif//ORCHID_UNISWAP_HPP
