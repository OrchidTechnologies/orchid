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


#ifndef ORCHID_VALVE_HPP
#define ORCHID_VALVE_HPP

#include "error.hpp"
#include "event.hpp"
#include "task.hpp"

namespace orc {

class Valve {
  public:
    static uint64_t Unique_;
    const uint64_t unique_ = ++Unique_;
    const char *type_ = typeid(Valve).name();

  private:
    Event shut_;

  protected:
    void Stop() noexcept {
        orc_insist(!shut_);
        shut_();
    }

  public:
    explicit Valve(bool set = false);
    virtual ~Valve();

    virtual task<void> Shut() noexcept {
        co_await shut_.Wait();
    }
};

template <typename Code_>
auto Using(Valve &valve, Code_ code) -> decltype(code()) {
    std::exception_ptr error;
    try {
        const auto value(co_await code());
        co_await valve.Shut();
        co_return value;
    } catch (...) {
        error = std::current_exception();
    }

    co_await valve.Shut();
    std::rethrow_exception(error);
}

template <typename Type_, typename Code_, typename... Args_>
auto Using(Code_ code, Args_ &&...args) -> decltype(code(std::declval<Type_ &>())) {
    Type_ valve(std::forward<Args_>(args)...);
    co_return co_await Using(valve, [&]() -> decltype(code(std::declval<Type_ &>())) {
        co_return co_await code(valve);
    });
}

}

#endif//ORCHID_VALVE_HPP
