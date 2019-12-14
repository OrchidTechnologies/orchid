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


#ifndef ORCHID_NEST_HPP
#define ORCHID_NEST_HPP

#include <atomic>

#include <cppcoro/single_consumer_async_auto_reset_event.hpp>

#include "log.hpp"
#include "task.hpp"
#include "valve.hpp"

namespace orc {

class Nest :
    public Valve
{
  private:
    unsigned limit_;
    std::atomic<unsigned> count_ = 0;
    cppcoro::single_consumer_async_auto_reset_event event_;

    class Count {
      private:
        Nest *nest_;
        unsigned count_;

      public:
        Count(Nest *nest) :
            nest_(nest),
            count_(++nest_->count_)
        {
            //Log() << "Nest[" << nest_ << "]: " << std::dec << count_ << std::endl;
        }

        Count(Count &&count) noexcept :
            nest_(count.nest_)
        {
            count.nest_ = nullptr;
        }

        ~Count() {
            if (nest_ == nullptr)
                return;
            const auto count(--nest_->count_);
            if (count == 0)
                nest_->event_.set();
            //Log() << "Nest[" << nest_ << "]: " << std::dec << count << std::endl;
        }

        operator unsigned() const {
            return count_;
        }
    };

  public:
    Nest(unsigned limit = -1) :
        limit_(limit)
    {
    }

    task<void> Shut() override {
        for (;;) {
            co_await event_;
        }
        co_await Valve::Shut();
    }

    template <typename Code_>
    void Hatch(Code_ code) {
        Count count(this);
        if (count > limit_)
            return;
        Spawn([count = std::move(count), code = code()]() mutable -> task<void> { try {
            co_await code();
        } catch (...) {
            // XXX: log error
        } });
    }
};

}

#endif//ORCHID_NEST_HPP
