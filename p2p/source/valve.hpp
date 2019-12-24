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


#ifndef ORCHID_VALVE_HPP
#define ORCHID_VALVE_HPP

#include "error.hpp"
#include "event.hpp"
#include "task.hpp"

namespace orc {

class Valve {
  public:
    static uint64_t Unique_;
    const uint64_t unique_ = ++Unique_;
    const char *type_ = typeid(Valve).name();

  private:
    static void Insert(Valve *valve);
    static void Remove(Valve *valve);

  private:
    Event shut_;

  protected:
    void Stop() noexcept {
        orc_insist(!shut_);
        shut_();
    }

  public:
    Valve() {
        Insert(this);
    }

    virtual ~Valve() {
        orc_insist_(shut_, "stuck " << type_);
        Remove(this);
    }

    virtual task<void> Shut() noexcept {
        co_await shut_.Wait();
    }
};

}

#endif//ORCHID_VALVE_HPP
