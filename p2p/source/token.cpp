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

task<Token> Token::New(unsigned milliseconds, S<Chain> chain, const char *name, const Address &contract, const Address &pool, const Float &adjust) {
    auto [bid, fiat] = *co_await Parallel(
        Opened(Updating(milliseconds, [chain]() -> task<uint256_t> { co_return co_await chain->Bid(); }, "Bid")),
        Opened(Updating(milliseconds, [chain, pool, adjust]() -> task<std::pair<Float, Float>> {
            const auto [under, other] = *co_await Parallel(Uniswap3(*chain, Uniswap3USDCETH, Ten6), pool == Address{} ? Freebie(Float(1)) : Uniswap3(*chain, pool, adjust));
            const auto ether(1 / under / Ten18);
            co_return std::make_tuple(ether, ether * other);
        }, name))
    );

    Currency ether{"ETH", [fiat = fiat]() -> Float { return std::get<0>((*fiat)()); }};
    Currency other{name, [fiat = fiat]() -> Float { return std::get<1>((*fiat)()); }};

    co_return Token{{std::move(chain), std::move(ether), std::move(bid)}, contract, std::move(other)};
}

task<Token> Token::AVAX(unsigned milliseconds, S<Ethereum> ethereum) {
    co_return co_await New(milliseconds, ethereum->chain_, "AVAX", "0x85f138bfee4ef8e540890cfb48f620571d67eda3", Uniswap3WAVAXETH);
}

task<Token> Token::BNB(unsigned milliseconds, S<Ethereum> ethereum) {
    co_return co_await New(milliseconds, ethereum->chain_, "BNB", {}, "0xba8080b0b09181e09bca0612b22b9475d8171055");
}

task<Token> Token::BTC(unsigned milliseconds, S<Ethereum> ethereum) {
    co_return co_await New(milliseconds, ethereum->chain_, "BTC", {}, "0x4585fe77225b41b697c938b018e2ac67ac5a20c0", Float("100000"));
}

task<Token> Token::ETH(unsigned milliseconds, S<Ethereum> ethereum) {
    co_return co_await New(milliseconds, ethereum->chain_, "ETH", {}, {});
}

task<Token> Token::FTM(unsigned milliseconds, S<Ethereum> ethereum) {
    co_return co_await New(milliseconds, ethereum->chain_, "FTM", {}, "0x3b685307c8611afb2a9e83ebc8743dc20480716e");
}

task<Token> Token::MATIC(unsigned milliseconds, S<Ethereum> ethereum) {
    co_return co_await New(milliseconds, ethereum->chain_, "MATIC", {}, "0x290a6a7460b308ee3f19023d2d00de604bcf5b42");
}

task<Token> Token::OXT(unsigned milliseconds, S<Ethereum> ethereum) {
    co_return co_await New(milliseconds, ethereum->chain_, "OXT", "0x4575f41308EC1483f3d399aa9a2826d74Da13Deb", Uniswap3OXTETH);
}

}
