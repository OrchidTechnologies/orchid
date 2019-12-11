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


#ifndef ORCHID_COINBASE_HPP
#define ORCHID_COINBASE_HPP

#include <string>

#include <boost/multiprecision/cpp_bin_float.hpp>

#include "task.hpp"

namespace orc {

typedef boost::multiprecision::cpp_bin_float_oct Float;

task<Float> Price(const std::string &from, const std::string &to, const Float &adjust);

}

#endif//ORCHID_COINBASE_HPP
