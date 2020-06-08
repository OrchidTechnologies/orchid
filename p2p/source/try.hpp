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


#ifndef ORCHID_TRY_HPP
#define ORCHID_TRY_HPP

#include "task.hpp"

namespace orc {

template <typename Type_, typename = std::enable_if_t<!std::is_void_v<Type_>>>
Task<Maybe<Type_>> Try(Task<Type_> &&task) noexcept { try {
    co_return Maybe<Type_>(std::in_place_index_t<1>(), co_await std::move(task));
} catch (...) {
    co_return Maybe<Type_>(std::in_place_index_t<0>(), std::current_exception());
} }

inline Task<Maybe<void>> Try(Task<void> &&task) noexcept { try {
    co_await std::move(task);
    co_return Maybe<void>(nullptr);
} catch (...) {
    co_return Maybe<void>(std::current_exception());
} }

}

#endif//ORCHID_TRY_HPP
