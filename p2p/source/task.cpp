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


#include <iostream>

#include <rtc_base/thread.h>

#include "trace.hpp"
#include "task.hpp"

namespace orc {

cppcoro::static_thread_pool &Executor() {
    static cppcoro::static_thread_pool pool_(1);
    return pool_;
}

cppcoro::static_thread_pool::schedule_operation Schedule() {
    return Executor().schedule();
}

static pthread_t thread_;

static struct SetupThread { SetupThread() {
    Wait([]() -> task<void> {
        co_await Schedule();
        thread_ = pthread_self();
        rtc::ThreadManager::Instance()->WrapCurrentThread();
    }());
} } SetupThread_;

bool Check() {
    return pthread_self() == thread_;
}

}
