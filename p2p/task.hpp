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
#include <cppcoro/sync_wait.hpp>
#include <cppcoro/task.hpp>

#include "task.hpp"

using cppcoro::task;

namespace orc {

cppcoro::static_thread_pool &Scheduler();
cppcoro::static_thread_pool::schedule_operation Schedule();

bool Check();

template <typename Code_>
void Task(Code_ code) {
    // XXX: I don't think I've ever been more upset by code
    std::thread([code = std::move(code)]() mutable {
        cppcoro::sync_wait([&code]() -> task<void> {
            co_await Schedule();
            co_await code();
        }());
    }).detach();
}

}

#endif//ORCHID_TASK_HPP
