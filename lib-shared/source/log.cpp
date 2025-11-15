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


#include <iostream>
#include <mutex>

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
#include "task.hpp"
#include "time.hpp"

// NOLINTBEGIN(cppcoreguidelines-avoid-non-const-global-variables)

#ifdef __APPLE__
extern "C" const char *__crashreporter_info__ = nullptr;
asm(".desc ___crashreporter_info__, 0x10");
#endif

namespace orc {

bool Verbose(false);

namespace {
    std::mutex mutex_;
    std::string cause_;
}

// NOLINTEND(cppcoreguidelines-avoid-non-const-global-variables)

void Log_(std::ostream &out, Fiber *fiber) {
    if (fiber == nullptr)
        return;
    Log_(out, fiber->Parent());
    out << "[F:" << fiber << "] ";
}

Log::Log(Fiber *fiber) noexcept { try {
    *this << "[@:" << std::dec << Monotonic() << "] ";
    *this << "[T:" << std::hex << pthread_self() << "] ";
    Log_(*this, fiber);
    *this << std::dec;
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

    const std::unique_lock<std::mutex> lock(mutex_);

#if 0
#elif defined(__APPLE__)
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg,cppcoreguidelines-pro-type-cstyle-cast)
    NSLog((NSString *)CFSTR("%s"), log.c_str());
#elif defined(__ANDROID__)
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg)
    __android_log_print(ANDROID_LOG_VERBOSE, "orchid", "%s", log.c_str());
#else
    std::cerr << log << std::endl;
#endif

    cause_ = std::move(log);
#ifdef __APPLE__
    __crashreporter_info__ = cause_.c_str();
#endif
} catch (...) {
    // XXX: maybe there's a backup plan?
} }

std::string Cause() {
    const std::unique_lock<std::mutex> lock(mutex_);
    return cause_;
}

}
