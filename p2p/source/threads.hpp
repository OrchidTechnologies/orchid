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


#ifndef ORCHID_THREADS_HPP
#define ORCHID_THREADS_HPP

#include <cppcoro/async_manual_reset_event.hpp>

#include "task.hpp"

namespace orc {

// XXX: support exceptions

template <typename Type_>
class Value {
  private:
    Type_ value_;

  public:
    template <typename Code_>
    void set(Code_ &code) {
        value_ = code();
    }

    Type_ get() {
        return std::move(value_);
    }
};

template <>
class Value<void> {
  public:
    template <typename Code_>
    void set(Code_ &code) {
        code();
    }

    void get() {
    }
};

template <typename Code_>
class Invoker :
    public rtc::MessageHandler
{
  private:
    typedef decltype(std::declval<Code_>()()) Type_;

    Code_ code_;

    Value<Type_> value_;
    cppcoro::async_manual_reset_event ready_;

  protected:
    void OnMessage(rtc::Message *message) override {
        value_.set(code_);
        ready_.set();
    }

  public:
    Invoker(Code_ code) :
        code_(std::move(code))
    {
    }

    task<Value<Type_>> operator ()(rtc::Thread *thread) {
        // potentially pass value/ready as MessageData
        orc_assert(!ready_.is_set());
        thread->Post(RTC_FROM_HERE, this);
        co_await ready_;
        co_return std::move(value_);
    }
};

class Threads {
  public:
    std::unique_ptr<rtc::Thread> signals_;
    std::unique_ptr<rtc::Thread> working_;

    static const Threads &Get();

  private:
    Threads();
};

template <typename Code_>
auto Post(Code_ code) noexcept(noexcept(code())) -> task<decltype(code())> {
    Invoker invoker(std::move(code));
    auto value(co_await invoker(Threads::Get().signals_.get()));
    co_await Schedule();
    co_return value.get();
}

}

#endif//ORCHID_THREADS_HPP
