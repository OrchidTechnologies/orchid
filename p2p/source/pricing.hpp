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


#ifndef ORCHID_PRICING_HPP
#define ORCHID_PRICING_HPP

#include <string>

#include "float.hpp"
#include "shared.hpp"
#include "task.hpp"

namespace orc {

class Base;
struct Currency;

task<Float> Binance(Base &base, const std::string &pair, const Float &adjust = Ten18);
task<Float> Coinbase(Base &base, const std::string &pair, const Float &adjust = Ten18);
task<Float> Kraken(Base &base, const std::string &pair, const Float &adjust = Ten18);

task<Currency> Binance(unsigned milliseconds, S<Base> base, std::string currency);

}

#endif//ORCHID_PRICING_HPP
