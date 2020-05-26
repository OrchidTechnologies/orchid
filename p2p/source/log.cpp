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


#ifdef __MINGW32__
#define _GNU_SOURCE
#endif

#include <iostream>

#include <pthread.h>

#if 0
#elif defined(__APPLE__)
#include <CoreFoundation/CoreFoundation.h>
typedef struct NSString NSString;
extern "C" void NSLog(NSString *, ...);
#elif defined(__ANDROID__)
#include <android/log.h>
#endif

#include <boost/algorithm/string.hpp>

#include "log.hpp"

namespace orc {

bool Verbose(false);

Log::Log(Fiber *fiber) noexcept { try {
    *this << "[T:" << pthread_self() << "] ";
    if (fiber != nullptr)
        *this << "[F:" << fiber << "] ";
} catch (...) {
} }

Log::~Log() { try {
    auto log(str());
    if (!log.empty() && log[log.size() - 1] == '\n')
        log.resize(log.size() - 1);

    boost::replace_all(log, "\r", "");
    boost::replace_all(log, "\n", " || ");

    if (log.find('\e') != std::string::npos)
        log += "\e[0m";

#if 0
#elif defined(__APPLE__)
    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-vararg,cppcoreguidelines-pro-type-cstyle-cast)
    NSLog((NSString *)CFSTR("%s"), log.c_str());
#elif defined(__ANDROID__)
    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-vararg)
    __android_log_print(ANDROID_LOG_VERBOSE, "orchid", "%s", log.c_str());
#else
    std::cerr << log << std::endl;
#endif
} catch (...) {
    // XXX: maybe there's a backup plan?
} }

}
