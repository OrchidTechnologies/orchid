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

static const Float Ten12("1000000000000");

task<Float> Uniswap(const Endpoint &endpoint, const Block &block, const Address &pair) {
    namespace mp = boost::multiprecision;
    typedef mp::number<mp::cpp_int_backend<256, 256, mp::unsigned_magnitude, mp::unchecked, void>> uint112_t;
    static const Selector<std::tuple<uint112_t, uint112_t, uint32_t>> getReserves_("getReserves");
    const auto [reserve0after, reserve1after, after] = co_await getReserves_.Call(endpoint, block.number_, pair, 90000);
#if 0
    const auto [reserve0before, reserve1before, before] = co_await getReserves_.Call(endpoint, block.number_ - 100, pair, 90000);
    static const Selector<uint256_t> price0CumulativeLast_("price0CumulativeLast");
    static const Selector<uint256_t> price1CumulativeLast_("price1CumulativeLast");
    const auto [price0before, price1before, price0after, price1after] = *co_await Parallel(
        price0CumulativeLast_.Call(endpoint, block.number_ - 100, pair, 90000),
        price1CumulativeLast_.Call(endpoint, block.number_ - 100, pair, 90000),
        price0CumulativeLast_.Call(endpoint, block.number_, pair, 90000),
        price1CumulativeLast_.Call(endpoint, block.number_, pair, 90000));
    std::cout << price0before << " " << reserve0before << " | " << price1before << " " << reserve1before << " | " << before << std::endl;
    std::cout << price0after << " " << reserve0after << " | " << price1after << " " << reserve1after << " | " << after << std::endl;
    std::cout << block.timestamp_ << std::endl;
#endif
    co_return Float(reserve0after) / Float(reserve1after);
}

task<S<Updated<Fiat>>> UniswapFiat(unsigned milliseconds, Endpoint endpoint) {
    co_return co_await Opened(Updating(60*1000, [endpoint]() -> task<Fiat> {
        const auto block(co_await endpoint.Header("latest"));
        const auto [usdc_weth, oxt_weth] = *co_await Parallel(
            Uniswap(endpoint, block, "0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc"),
            Uniswap(endpoint, block, "0x9b533f1ceaa5ceb7e5b8994ef16499e47a66312d"));
        co_return Fiat{Ten12 * usdc_weth / Ten18, Ten12 * usdc_weth / oxt_weth / Ten18};
    }, "Uniswap"));
}

}
