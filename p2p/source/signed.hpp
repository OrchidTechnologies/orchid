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


#ifndef ORCHID_SIGNED_HPP
#define ORCHID_SIGNED_HPP

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wconversion"
#include <boost/multiprecision/cpp_int.hpp>
#pragma clang diagnostic pop

namespace orc {

using boost::multiprecision::checked_int256_t;

template <unsigned Bits_, boost::multiprecision::cpp_integer_type Sign_, boost::multiprecision::cpp_int_check_type Check_>
using Integer = boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, Sign_, Check_>>;

template <unsigned Bits_, boost::multiprecision::cpp_int_check_type Check_>
Integer<Bits_, boost::multiprecision::unsigned_magnitude, boost::multiprecision::unchecked> Complement(const Integer<Bits_, boost::multiprecision::signed_magnitude, Check_> &value) {
    typedef Integer<Bits_, boost::multiprecision::unsigned_magnitude, boost::multiprecision::unchecked> Value;
    return Value(value);
}

template <unsigned Bits_, boost::multiprecision::cpp_int_check_type Check_>
Integer<Bits_, boost::multiprecision::signed_magnitude, boost::multiprecision::checked> Complement(const Integer<Bits_, boost::multiprecision::unsigned_magnitude, Check_> &value) {
    typedef Integer<Bits_, boost::multiprecision::signed_magnitude, boost::multiprecision::unchecked> Value;
    return bit_test(value, Bits_ - 1) ? -Value(~value + 1) : Value(value);
}

}

#endif//ORCHID_SIGNED_HPP
