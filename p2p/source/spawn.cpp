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


#include <iostream>
#include <thread>

#include <cppcoro/detail/lightweight_manual_reset_event.hpp>

#include <rtc_base/thread.h>

#include "error.hpp"
#include "spawn.hpp"

namespace orc {

class Pool {
  private:
    std::mutex mutex_;
    Work *begin_ = nullptr;
    Work **end_ = &begin_;

    cppcoro::detail::lightweight_manual_reset_event ready_;

  public:
    void Drain() {
        for (;;) {
            Work *work;
            { std::unique_lock<std::mutex> lock(mutex_);
                if (begin_ == nullptr)
                    return;
                work = begin_;
                begin_ = work->next_;
                if (end_ == &work->next_)
                    end_ = &begin_; }
            work->code_.resume();
        }
    }

    void Run() {
        for (;;) {
            ready_.reset();
            Drain();
            ready_.wait();
        }
    }

    void Push(Work *work) noexcept {
        { std::unique_lock<std::mutex> lock(mutex_);
            *end_ = work; end_ = &work->next_; }
        ready_.set();
    }
};

void Scheduled::await_suspend(std::experimental::coroutine_handle<> code) noexcept {
    code_ = code;
    pool_->Push(this);
}

Scheduled Schedule() {
    static Pool pool;
    static std::thread thread([]() {
        rtc::ThreadManager::Instance()->WrapCurrentThread();
        pool.Run();
    });
    return {&pool};
}

}
