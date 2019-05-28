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


#ifndef ORCHID_TASK_HPP
#define ORCHID_TASK_HPP

#include <functional>
#include <thread>

#include <cppcoro/sync_wait.hpp>
#include <cppcoro/task.hpp>

using cppcoro::task;

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
    return cppcoro::sync_wait(std::move(code));
}

struct Detached {
    struct promise_type {
        Detached get_return_object() {
            return {};
        }

        std::experimental::suspend_never initial_suspend() {
            return {};
        }

        std::experimental::suspend_never final_suspend() {
            return {};
        }

        void return_void() {
        }

        [[noreturn]]
        void unhandled_exception() {
            std::terminate();
        }
    };
};

template <typename Code_>
void Spawn(Code_ code) {
    [](Code_ code) mutable -> Detached {
        co_await Schedule();
        co_await code();
    }(std::move(code));
}

bool Check();

}

#endif//ORCHID_TASK_HPP
