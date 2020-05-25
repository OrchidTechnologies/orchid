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


#ifndef ORCHID_SPAWN_HPP
#define ORCHID_SPAWN_HPP

#include <cppcoro/sync_wait.hpp>
#include <cppcoro/task.hpp>

#include "task.hpp"

namespace orc {

class Pool;

struct Stacked {
    Stacked *next_ = nullptr;
    std::experimental::coroutine_handle<> code_;
};

class Scheduled :
    protected Stacked
{
  private:
    Pool *pool_;

  public:
    Scheduled(Pool *pool) :
        pool_(pool)
    {
    }

    bool await_ready() noexcept {
        return false;
    }

    void await_suspend(std::experimental::coroutine_handle<> code) noexcept;

    void await_resume() noexcept {
    }
};

Scheduled Schedule();

template <typename Type_>
Type_ Wait(task<Type_> code) {
    // XXX: centralize Schedule?
    return cppcoro::sync_wait([](task<Type_> code) mutable -> cppcoro::task<Type_> {
        co_return co_await std::move(code);
    }(std::move(code)));
}

class Detached {
  public:
    class promise_type {
      public:
        auto get_return_object() noexcept {
            return Detached();
        }

        auto initial_suspend() noexcept {
            return std::experimental::suspend_never(); }
        auto final_suspend() noexcept {
            return std::experimental::suspend_never(); }

        [[noreturn]] void unhandled_exception() noexcept {
            std::terminate();
        }

        void return_void() noexcept {
        }
    };
};

template <typename Code_>
auto Spawn(Code_ code) noexcept -> typename std::enable_if<noexcept(code())>::type {
    [](Code_ code) mutable noexcept -> Detached {
        co_await Schedule();
        co_await code();
    }(std::move(code));
}

}

#endif//ORCHID_SPAWN_HPP
