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


#ifndef ORCHID_LINK_HPP
#define ORCHID_LINK_HPP

#include "buffer.hpp"
#include "drain.hpp"
#include "error.hpp"
#include "shared.hpp"
#include "task.hpp"
#include "valve.hpp"

namespace orc {

template <typename Type_>
class Pipe {
  public:
    virtual ~Pipe() = default;
    virtual task<void> Send(const Type_ &data) = 0;
};

template <typename Basin_>
class Faucet :
    public Valve
{
  private:
    Basin_ &basin_;

  protected:
    Basin_ &Outer() {
        return basin_;
    }

    void Stop(const std::string &error = std::string()) noexcept {
        Valve::Stop();
        return Outer().Stop(error);
    }

  public:
    Faucet(Basin_ &basin) :
        basin_(basin)
    {
    }
};

template <typename Type_, typename Value_ = const Type_ &>
class Pump :
    public Faucet<Drain<Value_>>,
    public Pipe<Type_>
{
  protected:
    void Land(const Type_ &data) {
        return Faucet<Drain<Value_>>::Outer().Land(data);
    }

  public:
    Pump(Drain<Value_> &drain) :
        Faucet<Drain<Value_>>(drain)
    {
    }
};

template <typename Type_>
class Link :
    public Pump<Type_>,
    public Drain<const Type_ &>
{
  protected:
    void Land(const Buffer &data) override {
        return Pump<Type_>::Land(data);
    }

    void Stop(const std::string &error = std::string()) noexcept override {
        return Pump<Type_>::Stop(error);
    }

  public:
    Link(Drain<const Buffer &> &drain) :
        Pump<Type_>(drain)
    {
    }
};

using BufferDrain = Drain<const Buffer &>;
using BufferSunk = Sunk<BufferDrain, Pump<Buffer>>;

template <typename Base_>
using BufferSink = Sink<Base_, BufferDrain>;

}

#endif//ORCHID_LINK_HPP
