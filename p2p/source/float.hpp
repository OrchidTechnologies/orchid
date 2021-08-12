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


#ifndef ORCHID_FLOAT_HPP
#define ORCHID_FLOAT_HPP

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconversion"
#include <boost/multiprecision/cpp_bin_float.hpp>
#pragma clang diagnostic pop

#include "error.hpp"

namespace orc {

typedef boost::multiprecision::cpp_bin_float_oct Float;

static const Float Ten9("1000000000");
static const Float Ten18("1000000000000000000");

template <typename Type_>
std::enable_if_t<std::is_same_v<Type_, double>, Type_> To(const std::string_view &value) {
    const auto start(value.data());
    const auto size(value.size());
    char *end;
    const auto number(strtod(start, &end));
    orc_assert(end == start + size);
    return number;
}

}

#endif//ORCHID_FLOAT_HPP
