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


#ifndef ORCHID_THREADS_HPP
#define ORCHID_THREADS_HPP

#include <rtc_base/thread.h>

#include "event.hpp"

namespace orc {

template <typename Type_>
class Result {
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
class Result<void> {
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

    std::exception_ptr error_;
    Result<Type_> result_;
    Event ready_;

  protected:
    void OnMessage(rtc::Message *message) override {
        try {
            result_.set(code_);
        } catch (const std::exception &exception) {
            error_ = std::current_exception();
        }

        ready_();
    }

  public:
    Invoker(Code_ code) :
        rtc::MessageHandler(false),
        code_(std::move(code))
    {
    }

    task<Result<Type_>> operator ()(const rtc::Location &location, rtc::Thread &thread) {
        // potentially pass value/ready as MessageData
        orc_assert(!ready_);
        thread.Post(location, this);
        co_await *ready_;
        if (error_)
            std::rethrow_exception(error_);
        co_return std::move(result_);
    }
};

class Threads {
  public:
    std::unique_ptr<rtc::Thread> signals_;

    static const Threads &Get();

  private:
    Threads();
};

template <typename Code_>
auto Post(Code_ code, const rtc::Location &location, rtc::Thread &thread) noexcept(noexcept(code())) -> task<decltype(code())> {
    Invoker invoker(std::move(code));
    auto value(co_await invoker(location, thread));
    co_return value.get();
}

template <typename Code_>
auto Post(Code_ code, const rtc::Location &location) noexcept(noexcept(code())) -> task<decltype(code())> {
    co_return co_await Post(std::move(code), location, *Threads::Get().signals_);
}

}

#endif//ORCHID_THREADS_HPP
