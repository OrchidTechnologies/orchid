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


#ifndef ORCHID_NEST_HPP
#define ORCHID_NEST_HPP

#include <atomic>

#include <cppcoro/single_consumer_event.hpp>

#include "log.hpp"
#include "spawn.hpp"
#include "task.hpp"
#include "time.hpp"
#include "valve.hpp"

namespace orc {

class Nest final :
    public Covered<Valve>
{
  private:
    std::atomic<unsigned> limit_;
    std::atomic<unsigned> count_ = 0;
    Event event_;

    class Count {
      private:
        Nest *nest_;
        unsigned count_;

      public:
        Count(Nest *nest) noexcept :
            nest_(nest),
            count_(++nest_->count_)
        {
            //Log() << "Nest[" << nest_ << "]: " << std::dec << count_ << std::endl;
        }

        Count(Count &&count) noexcept :
            nest_(count.nest_),
            count_(count.count_)
        {
            count.nest_ = nullptr;
            count.count_ = 0;
        }

        ~Count() {
            if (nest_ == nullptr)
                return;
            const auto count(--nest_->count_);
            if (count == 0 && nest_->limit_ == 0)
                nest_->event_();
            //Log() << "Nest[" << nest_ << "]: " << std::dec << count << std::endl;
        }

        operator unsigned() const noexcept {
            return count_;
        }
    };

  public:
    Nest(unsigned limit = -1) :
        Covered(typeid(*this).name()),
        limit_(limit)
    {
    }

    task<void> Shut() noexcept override {
        limit_ = 0;
        while (count_ != 0)
            co_await *event_;
        Valve::Stop();
        co_await Valve::Shut();
    }

    template <typename Code_>
    auto Hatch(Code_ code, const char *name) noexcept -> typename std::enable_if_t<noexcept(code()), bool> {
        Count count(this);
        if (count > limit_)
            return false;
        Spawn([
#if ORC_TIMEOUT
            before = Monotonic(),
#endif
        count = std::move(count), code = code()]() mutable noexcept -> task<void> {
            orc_ignore({ co_await code(); });
#if ORC_TIMEOUT
            const auto duration(Monotonic() - before);
            if (duration > ORC_TIMEOUT)
                Log() << std::dec << duration << " us";
#endif
        }, name);
        return true;
    }
};

}

#endif//ORCHID_NEST_HPP
