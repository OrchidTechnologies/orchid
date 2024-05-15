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


#include <cppcoro/detail/lightweight_manual_reset_event.hpp>

#include <rtc_base/thread.h>

#include "error.hpp"
#include "spawn.hpp"

namespace orc {

Pool::Pool() :
    thread_([this]() {
        rtc::ThreadManager::Instance()->WrapCurrentThread();
        rtc::SetCurrentThreadName("orchid:tasks");

        for (;ready_.reset(), true; ready_.wait()) for (;;) {
            Work *work;
            { const std::unique_lock<std::mutex> lock(mutex_);
                if (end_ == nullptr)
                    return;
                if (begin_ == nullptr)
                    break;
                work = begin_;
                begin_ = work->next_;
                work->next_ = nullptr;
                if (end_ == &work->next_)
                    end_ = &begin_; }
            work->code_.resume();
        }
    })
{
}

Pool::~Pool() {
    { const std::unique_lock<std::mutex> lock(mutex_);
        end_ = nullptr; }
    ready_.set();
    thread_.join();
}

void Pool::Push(Work *work) noexcept {
    { const std::unique_lock<std::mutex> lock(mutex_);
        if (end_ == nullptr)
            return;
        *end_ = work; end_ = &work->next_; }
    ready_.set();
}

void Pool::Scheduled::await_suspend(std::experimental::coroutine_handle<> code) noexcept {
    code_ = code;
    pool_->Push(this);
}

Pool &Schedule() {
    static Pool pool;
    return pool;
}

}
