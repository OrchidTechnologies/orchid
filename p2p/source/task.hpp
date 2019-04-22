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

#include <cppcoro/static_thread_pool.hpp>

namespace orc {

void Post(std::function<void ()> code);

bool Check();

}

#ifdef ORCHID_CPPCORO

#include <cppcoro/task.hpp>
#include <cppcoro/sync_wait.hpp>

using cppcoro::task;

namespace orc {

cppcoro::static_thread_pool &Executor();
cppcoro::static_thread_pool::schedule_operation Schedule();

template <typename Type_>
Type_ Wait(task<Type_> code) {
    return cppcoro::sync_wait(std::move(code));
}

template <typename Code_>
void Task(Code_ code) {
    // XXX: I don't think I've ever been more upset by code
    std::thread([code = std::move(code)]() mutable {
        Wait([&code]() -> task<void> {
            co_await Schedule();
            co_await code();
        }());
    }).detach();
}

}

#else

#include <folly/experimental/coro/Task.h>
#include <folly/experimental/coro/BlockingWait.h>

namespace orc {

folly::Executor *Executor();

}

#if 0

template <typename Type_>
using task = folly::coro::Task<Type_>;

namespace orc {

template <typename Type_>
Type_ Wait(task<Type_> code) {
    return folly::coro::blockingWait(std::move(code));
}

template <typename Code_>
void Task(Code_ code) {
    folly::coro::co_invoke(std::move(code)).scheduleOn(Executor()).start();
}

}

#else

#include <folly/experimental/coro/detail/InlineTask.h>

template <typename Type_>
using task = folly::coro::detail::InlineTask<Type_>;

namespace orc {
template <typename Type_>
Type_ Wait(task<Type_> code) {
    return folly::coro::blockingWait([code = std::move(code)]() mutable -> folly::coro::Task<Type_> {
        co_return co_await std::move(code);
    }());
}

template <typename Code_>
void Task(Code_ code) {
    folly::coro::co_invoke([code = std::move(code)]() mutable -> folly::coro::Task<void> {
        co_await code();
    }).scheduleOn(Executor()).start();
}

inline task<void> Schedule() {
    co_await []() -> folly::coro::Task<void> {
        co_return;
    }().scheduleOn(Executor());
}

}

#endif

#endif

#endif//ORCHID_TASK_HPP
