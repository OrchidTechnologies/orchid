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


#include "binance.hpp"
#include "currency.hpp"
#include "token.hpp"

namespace orc {

Currency Currency::USD() {
    return Currency{"USD", []() -> Float { return 1 / Ten18; }};
}

task<Currency> Currency::New(unsigned milliseconds, const S<Ethereum> &ethereum, const S<Base> &base, std::string name) {
    if (false);
    else if (name == "AVAX")
        co_return (co_await Token::AVAX(milliseconds, ethereum)).currency_;
    else if (name == "BNB")
        co_return (co_await Token::BNB(milliseconds, ethereum)).currency_;
    else if (name == "BTC")
        co_return (co_await Token::BTC(milliseconds, ethereum)).currency_;
    else if (name == "DAI")
        co_return Currency::USD();
    else if (name == "FTM")
        co_return (co_await Token::FTM(milliseconds, ethereum)).currency_;
    else if (name == "MATIC")
        co_return (co_await Token::MATIC(milliseconds, ethereum)).currency_;
    else if (name == "OXT")
        co_return (co_await Token::OXT(milliseconds, ethereum)).currency_;
    else if (name == "USD")
        co_return Currency::USD();
    else
        co_return co_await Binance(milliseconds, base, std::move(name));
}

}
