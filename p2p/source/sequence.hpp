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


#ifndef ORCHID_SEQUENCE_HPP
#define ORCHID_SEQUENCE_HPP

#include <vector>

#include <boost/range/combine.hpp>

namespace orc {

template <typename Code_, typename Data_>
auto Map(Code_ &&code, const Data_ &data) {
    std::vector<std::decay_t<decltype(code(*data.begin()))>> mapped;
    mapped.reserve(data.size());
    for (const auto &value : data)
        mapped.emplace_back(code(value));
    return mapped;
}

template <typename ...Args_>
auto Zip(Args_ &&...args) {
    return boost::combine(std::forward<Args_>(args)...);
}

}

#endif//ORCHID_SEQUENCE_HPP
