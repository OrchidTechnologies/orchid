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


#ifndef ORCHID_INTEGER_HPP
#define ORCHID_INTEGER_HPP

#include <charconv>
#include <string>

#include <boost/multiprecision/cpp_int.hpp>

#include "error.hpp"

namespace orc {

template <unsigned Bits_>
using uint_t = boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::unsigned_magnitude, boost::multiprecision::unchecked>>;

using boost::multiprecision::uint128_t;
using boost::multiprecision::uint256_t;

inline bool operator ==(const std::from_chars_result &lhs, const std::from_chars_result &rhs) {
    return lhs.ptr == rhs.ptr && lhs.ec == rhs.ec;
}

template <typename Type_>
std::enable_if_t<std::is_integral_v<Type_>, Type_> To(const std::string_view &value) {
    auto start(value.data());
    const auto size(value.size());
    const auto end(start + size);
    const auto base([&]() -> int {
        if (size < 2 || start[0] != '0' || start[1] != 'x')
            return 10;
        start += 2;
        return 16;
    }());
    Type_ number;
    orc_assert_((std::from_chars(start, end, number, base) == std::from_chars_result{end, std::errc()}), value << " is not a number");
    return number;
}

template <typename Type_, typename From_>
Type_ Fit(const From_ &value) {
    orc_assert(value <= std::numeric_limits<Type_>::max());
    return Type_(value);
}

}

#endif//ORCHID_INTEGER_HPP
