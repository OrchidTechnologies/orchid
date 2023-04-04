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


#ifndef ORCHID_SCOPE_HPP
#define ORCHID_SCOPE_HPP

#include <utility>

// http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2014/n4152.pdf

#ifdef __cpp_exceptions
#define uncaught_exceptions cy_uncaught_exceptions

namespace __cxxabiv1 {
    struct __cxa_eh_globals;
    extern "C" __cxa_eh_globals *__cxa_get_globals() noexcept;
}

namespace std {
inline int uncaught_exceptions() noexcept {
    return *reinterpret_cast<int *>(reinterpret_cast<char *>(__cxxabiv1::__cxa_get_globals()) + sizeof(void *));
} }
#endif

template <typename Code_>
class scope {
  private:
#ifdef __cpp_exceptions
    const int uncaught_;
#endif
    bool valid_;
    Code_ function_;

  public:
    scope(Code_ &&function) :
#ifdef __cpp_exceptions
        uncaught_(std::uncaught_exceptions()),
#endif
        valid_(true),
        function_(std::move(function))
    {
    }

    // XXX: consider if this Impactor behavior is sane
    ~scope() noexcept(false) {
        if (!valid_);
#ifdef __cpp_exceptions
        else if (std::uncaught_exceptions() == uncaught_)
            function_();
        else try {
            function_();
        } catch (...) {
        }
#else
        else
            function_();
#endif
    }

    void operator()() {
        auto function(std::move(function_));
        clear();
        function();
    }

    void clear() {
        valid_ = false;
    }
};

#if __cpp_exceptions
#undef uncaught_exceptions
#endif

#define _scope__(code, line) \
    scope _scope ## line([&]code)
#define _scope_(code, line) \
    _scope__(code, line)
#define _scope(code) \
    _scope_(code, __LINE__)

#endif//ORCHID_SCOPE_HPP
