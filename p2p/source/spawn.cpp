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
#include <thread>

#include <cppcoro/detail/lightweight_manual_reset_event.hpp>

#include <rtc_base/thread.h>

#include "error.hpp"
#include "spawn.hpp"

namespace orc {

// XXX: audit and correct the std::atomic usage in Pool
// XXX: this should be a priority / deadline scheduler

class Pool {
  private:
    std::atomic<Stacked *> stack_ = nullptr;
    cppcoro::detail::lightweight_manual_reset_event ready_;

  public:
    void Drain() {
        for (;;) {
            auto stacked(stack_.load()); do {
                if (stacked == nullptr)
                    return;
            } while (!stack_.compare_exchange_strong(stacked, stacked->next_));
            stacked->code_.resume();
        }
    }

    void Run() {
        for (;;) {
            ready_.reset();
            Drain();
            ready_.wait();
        }
    }

    void Stack(Stacked *stacked) noexcept {
        orc_insist(stacked->next_ == nullptr);

        auto stack(stack_.load()); do {
            stacked->next_ = stack;
        } while (!stack_.compare_exchange_strong(stack, stacked));

        ready_.set();
    }
};

void Scheduled::await_suspend(std::experimental::coroutine_handle<> code) noexcept {
    code_ = code;
    pool_->Stack(this);
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
