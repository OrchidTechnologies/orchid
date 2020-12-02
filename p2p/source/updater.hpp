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


#ifndef ORCHID_UPDATER_HPP
#define ORCHID_UPDATER_HPP

#include "sleep.hpp"
#include "updated.hpp"
#include "valve.hpp"

namespace orc {

template <typename Code_>
class Updater :
    public Updated<typename decltype(std::declval<Code_>()())::Value>,
    public Valve
{
  private:
    unsigned milliseconds_;
    Code_ code_;

    Event ready_;

  public:
    Updater(unsigned milliseconds, Code_ &&code, const char *name) :
        Valve(typeid(*this).name()),
        milliseconds_(milliseconds),
        code_(std::move(code))
    {
        Spawn([this]() noexcept -> Task<void> {
            co_await ready_([this]() -> task<void> {
                co_await Update();
            }());

            for (;;) {
                co_await Sleep(milliseconds_);
                orc_ignore({ co_await Update(); });
            }

            Stop();
        }, name);
    }

    task<void> Update() override {
        auto value(co_await code_());
        std::swap(*this->value_(), value);
    }

    Task<void> Open() override {
        co_await *ready_;
    }

    Task<void> Shut() noexcept override {
        co_await Valve::Shut();
    }
};

template <typename Code_>
auto Updating(unsigned milliseconds, Code_ &&code, const char *name) {
    return Break<Updater<Code_>>(milliseconds, std::forward<Code_>(code), name);
}

}

#endif//ORCHID_UPDATER_HPP
