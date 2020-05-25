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


#ifndef ORCHID_EVENT_HPP
#define ORCHID_EVENT_HPP

#include <cppcoro/async_manual_reset_event.hpp>
#include <cppcoro/single_consumer_event.hpp>

#include "spawn.hpp"

namespace orc {

// XXX: replace Wait() with operator co_await

template <typename Type_>
class Transfer {
  private:
    cppcoro::async_manual_reset_event ready_;
    Type_ value_;

  public:
    operator bool() {
        return ready_.is_set();
    }

    void operator ()(Type_ &&value) noexcept {
        std::swap(value_, value);
        ready_.set();
    }

    task<Type_> Wait() {
        co_await ready_;
        co_await Schedule();
        co_return std::move(value_);
    }
};

template <>
class Transfer<void> {
  private:
    cppcoro::async_manual_reset_event ready_;

  public:
    explicit Transfer(bool set = false) :
        ready_(set)
    {
    }

    operator bool() {
        return ready_.is_set();
    }

    void operator ()() noexcept {
        ready_.set();
    }

    task<void> Wait() {
        co_await ready_;
        co_await Schedule();
    }
};

typedef Transfer<void> Event;

}

#endif//ORCHID_EVENT_HPP
