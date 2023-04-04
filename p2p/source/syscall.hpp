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


#ifndef ORCHID_SYSCALL_HPP
#define ORCHID_SYSCALL_HPP

#include "error.hpp"

// XXX: orc_syscall happens to only be used on Windows for WinSock ;P
#ifdef _WIN32
#define orc_errno WSAGetLastError()
#else
#define orc_errno errno
#endif

// XXX: this is *ridiculous*, but lambdas break structured binding :/
#define orc_syscall(expr, ...) ({ decltype(expr) _value; for (;;) { \
    _value = (expr); \
    if ((long) _value != -1) \
        break; \
    int error(orc_errno); \
    _value = 0; \
    for (auto success : std::initializer_list<long>{__VA_ARGS__}) \
        if (error == success) \
            _value = (decltype(expr)) -success; \
    if (_value != 0) \
        break; \
    if (error == EINTR) \
        continue; \
    orc_throw(error << "=\"" << strerror(error) << "\" calling " << #expr); \
} _value; })

#define orc_packed \
    __attribute__((__packed__))

#endif//ORCHID_SYSCALL_HPP
