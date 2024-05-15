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
#include "parallel.hpp"
#include "uniswap.hpp"

namespace orc {

const Address Uniswap2OXTETH("0x9B533F1cEaa5ceb7e5b8994ef16499E47A66312D");
const Address Uniswap2USDCETH("0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc");

const Address Uniswap3ETHUSDT("0x4e68Ccd3E89f51C3074ca5072bbAC773960dFa36");
const Address Uniswap3OXTETH("0x820e5ab3d952901165f858703ae968e5ea67eb31");
const Address Uniswap3USDCETH("0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8");
const Address Uniswap3WAVAXETH("0x00C6A247a868dEE7e84d16eBa22D1Ab903108a44");

task<Float> Uniswap2(const Chain &chain, const Address &pool, const Float &adjust) {
    typedef uint256_t uint112_t;
    static const Selector<std::tuple<uint112_t, uint112_t, uint32_t>> getReserves("getReserves");
    const auto [reserve0after, reserve1after, after] = co_await getReserves.Call(chain, "latest", pool, 90000);
    co_return Float(reserve0after) / Float(reserve1after) / adjust;
}

task<Float> Uniswap3(const Chain &chain, const Address &pool, const Float &adjust) {
    typedef uint256_t int24_t;
    static const Selector<std::tuple<uint160_t, int24_t, uint16_t, uint16_t, uint16_t, uint8_t, bool>> slot0("slot0");
    const auto [sqrtPriceX96, tick, observationIndex, observationCardinality, observationCardinalityNext, feeProtocol, unlocked] = co_await slot0.Call(chain, "latest", pool, 90000);
    const auto square(Float(sqrtPriceX96) / adjust / Two96);
    co_return square * square;
}

}
