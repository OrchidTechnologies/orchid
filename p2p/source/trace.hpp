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

#if defined(__APPLE__)
#include <CoreFoundation/CoreFoundation.h>
#ifndef __OBJC__
typedef struct NSString NSString;
#endif
extern "C" void NSLog(NSString *, ...);
#define _trace() \
    NSLog((NSString *) CFSTR("[%llx] _trace(%s:%u): %s"), (long long) pthread_self(), __FILE__, __LINE__, __FUNCTION__)
#elif defined(__cplusplus)
#include <cstdio>
#define _trace() do { \
    std::cerr << "\e[31m[" << std::hex << pthread_self() << "] _trace(" << __FILE__ << ":" << std::dec << __LINE__ << "): " << __FUNCTION__ << "\e[0m" << std::endl; \
} while (false)
#else
#include <stdio.h>
#define _trace() \
    fprintf(stderr, "\e[31m[%llx] _trace(%s:%u): %s\e[0m\n", (long long) pthread_self(), __FILE__, __LINE__, __FUNCTION__)
#endif

#endif//ORCHID_TRACE_HPP
