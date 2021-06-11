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
#include "token.hpp"
#include "uniswap.hpp"
#include "updater.hpp"

namespace orc {

task<Token> Token::OXT(unsigned milliseconds, S<Chain> chain) {
    auto [bid, fiat] = *co_await Parallel(
        Opened(Updating(milliseconds, [chain]() -> task<uint256_t> { co_return co_await chain->Bid(); }, "Bid")),
        Opened(Updating(milliseconds, [chain]() -> task<std::pair<Float, Float>> {
            const auto [eth, oxt] = *co_await Parallel(Uniswap2(*chain, Uniswap2USDCETH, Ten6), Uniswap2(*chain, Uniswap2OXTETH, 1));
            co_return std::make_tuple(eth, eth / oxt);
        }, "OXT"))
    );

    Currency eth{"ETH", [fiat = fiat]() -> Float { return std::get<0>((*fiat)()); }};
    Currency oxt{"OXT", [fiat = fiat]() -> Float { return std::get<1>((*fiat)()); }};

    co_return Token{{std::move(chain), std::move(eth), std::move(bid)}, "0x4575f41308EC1483f3d399aa9a2826d74Da13Deb", std::move(oxt)};
}

}
