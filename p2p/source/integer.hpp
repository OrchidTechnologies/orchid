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


#ifndef ORCHID_INTEGER_HPP
#define ORCHID_INTEGER_HPP

#include <string>

#include <boost/multiprecision/cpp_int.hpp>

#include "error.hpp"

namespace orc {

using boost::multiprecision::uint128_t;
using boost::multiprecision::uint256_t;

inline unsigned long To(const std::string &value) {
    size_t end;
    const auto number(stoul(value, &end));
    orc_assert(end == value.size());
    return number;
}

}

#endif//ORCHID_INTEGER_HPP
