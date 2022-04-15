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


#ifndef ORCHID_TOKEN_HPP
#define ORCHID_TOKEN_HPP

#include "currency.hpp"
#include "jsonrpc.hpp"
#include "market.hpp"
#include "shared.hpp"
#include "task.hpp"

namespace orc {

struct Token {
    const Market market_;
    const Address contract_;
    const Currency currency_;

    static task<Token> New(unsigned milliseconds, S<Chain> chain, const char *name, const Address &contract, const Address &pool, const Float &adjust = 1);

    static task<Token> AVAX(unsigned milliseconds, S<Ethereum> ethereum);
    static task<Token> BNB(unsigned milliseconds, S<Ethereum> ethereum);
    static task<Token> BTC(unsigned milliseconds, S<Ethereum> ethereum);
    static task<Token> FTM(unsigned milliseconds, S<Ethereum> ethereum);
    static task<Token> MATIC(unsigned milliseconds, S<Ethereum> ethereum);
    static task<Token> OXT(unsigned milliseconds, S<Ethereum> ethereum);
};

}

#endif//ORCHID_TOKEN_HPP
