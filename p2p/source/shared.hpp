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


#ifndef ORCHID_SHARED_HPP
#define ORCHID_SHARED_HPP

#include <memory>
#include <utility>

namespace orc {

template <typename Type_>
using U = std::unique_ptr<Type_>;

template <typename Type_>
using W = std::weak_ptr<Type_>;

#if 0
template <typename Type_>
class Shared :
    public std::shared_ptr<Type_>
{
  public:
    using std::shared_ptr<Type_>::shared_ptr;
};

template <typename Type_>
using S = Shared<Type_>;
#else
template <typename Type_>
using S = std::shared_ptr<Type_>;
#endif

template <typename Type_, typename... Args_>
inline S<Type_> Make(Args_ &&...args) {
    return std::move(std::make_shared<Type_>(std::forward<Args_>(args)...));
}

}

#endif//ORCHID_SHARED_HPP
