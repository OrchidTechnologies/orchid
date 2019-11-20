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


#ifndef ORCHID_UTILITY_HPP
#define ORCHID_UTILITY_HPP

#include <tuple>

namespace orc {

template <size_t L, typename... T, std::size_t... I>
auto Pick(const std::tuple<T...> &data, std::index_sequence<I...>) {
    return std::make_tuple(std::get<I + L>(data)...);
}

template <size_t L, size_t R, typename... T>
auto Slice(const std::tuple<T...> &data) {
    return Pick<L>(data, std::make_index_sequence<R - L>());
}

}

#endif//ORCHID_UTILITY_HPP
