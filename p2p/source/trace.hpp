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


#ifndef ORCHID_TRACE_HPP
#define ORCHID_TRACE_HPP

#include <pthread.h>

#include "log.hpp"

#define _trace() do { \
    Log() << "\e[31m[" << std::hex << pthread_self() << "] _trace(" << __FILE__ << ":" << std::dec << __LINE__ << "): " << __FUNCTION__ << "\e[0m" << std::endl; \
} while (false)

#endif//ORCHID_TRACE_HPP
