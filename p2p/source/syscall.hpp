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


#ifndef ORCHID_SYSCALL_HPP
#define ORCHID_SYSCALL_HPP

#include "error.hpp"

#define orc_syscall(expr, ...) [&] { for (;;) { \
    auto _value(expr); \
    if ((long) _value != -1) \
        return _value; \
    int error(errno); \
    if (error == EINTR) \
        continue; \
    for (auto success : std::initializer_list<long>({__VA_ARGS__})) \
        if (error == success) \
            return (decltype(expr)) -success; \
    orc_throw(error); \
} }()

#ifdef __MINGW32__
#define orc_packed \
    __attribute__((__packed__, __gcc_struct__))
#else
#define orc_packed \
    __attribute__((__packed__))
#endif

#endif//ORCHID_SYSCALL_HPP
