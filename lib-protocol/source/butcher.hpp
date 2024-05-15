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


#ifndef ORCHID_BUTCHER_HPP
#define ORCHID_BUTCHER_HPP

#include <tuple>

namespace orc {

template <size_t Left_, typename... Type_, std::size_t... Index_>
auto Pick(const std::tuple<Type_...> &data, std::index_sequence<Index_...>) {
    return std::make_tuple(std::get<Index_ + Left_>(data)...);
}

template <size_t Left_, size_t Right_, typename... Type_>
auto Slice(const std::tuple<Type_...> &data) {
    return Pick<Left_>(data, std::make_index_sequence<Right_ - Left_>());
}

}

#endif//ORCHID_BUTCHER_HPP
