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


#ifndef ORCHID_TUBE_HPP
#define ORCHID_TUBE_HPP

#include "link.hpp"

namespace orc {

class Tube :
    public Link<Buffer>,
    public Sunken<Pump<Buffer>>
{
  public:
    Tube(BufferDrain &drain) :
        Link<Buffer>(typeid(*this).name(), drain)
    {
    }

    task<void> Shut() noexcept override {
        co_await Sunken::Shut();
        co_await Link::Shut();
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await Inner().Send(data);
    }
};

class Stopper :
    public Valve,
    public BufferDrain,
    public Sunken<Pump<Buffer>>
{
  protected:
    void Land(const Buffer &buffer) override {
    }

    void Stop(const std::string &error) noexcept override {
    }

  public:
    Stopper() :
        Valve(typeid(*this).name())
    {
    }

    task<void> Shut() noexcept override {
        co_await Sunken::Shut();
        co_await Valve::Shut();
    }
};

class Cap :
    public Pump<Buffer>
{
  public:
    Cap(Drain<const Buffer &> &drain) :
        Pump(typeid(*this).name(), drain)
    {
    }

    task<void> Shut() noexcept override {
        Pump::Stop();
        co_await Pump::Shut();
    }

    task<void> Send(const Buffer &data) override {
        orc_assert(false);
    }
};

}

#endif//ORCHID_TUBE_HPP
