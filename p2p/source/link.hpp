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

class Basin {
  public:
    virtual void Stop(const std::string &error = std::string()) = 0;
};

template <typename Type_>
class Drain :
    public Basin
{
  public:
    virtual void Land(Type_ data) = 0;
};

template <typename Basin_>
class Faucet :
    public Valve
{
  private:
    Basin_ *const basin_;

  protected:
    Basin_ *Outer() {
        return basin_;
    }

    void Stop(const std::string &error = std::string()) {
        Valve::Stop();
        return Outer()->Stop(error);
    }

  public:
    Faucet(Basin_ *basin) :
        basin_(basin)
    {
    }
};

using BufferDrain = Drain<const Buffer &>;

class Pump :
    public Faucet<BufferDrain>,
    public Pipe<Buffer>
{
  protected:
    void Land(const Buffer &data) {
        return Outer()->Land(data);
    }

  public:
    Pump(BufferDrain *drain) :
        Faucet<BufferDrain>(drain)
    {
    }
};

class Stopper :
    public Valve,
    public BufferDrain
{
  protected:
    virtual Pump *Inner() = 0;

    void Land(const Buffer &buffer) override {
    }

    void Stop(const std::string &error) override {
    }

  public:
    task<void> Shut() override {
        co_await Inner()->Shut();
        co_await Valve::Shut();
    }
};

class Link :
    public Pump,
    public BufferDrain
{
  protected:
    void Land(const Buffer &data) override {
        return Pump::Land(data);
    }

    void Stop(const std::string &error = std::string()) override {
        return Pump::Stop(error);
    }

  public:
    Link(BufferDrain *drain) :
        Pump(drain)
    {
    }
};

template <typename Inner_ = Pump, typename Drain_ = BufferDrain>
class Sunk {
  protected:
    U<Inner_> inner_;

    virtual Drain_ *Gave() = 0;

  public:
    template <typename Type_, typename... Args_>
    Type_ *Wire(Args_ &&...args) {
        auto inner(std::make_unique<Type_>(Gave(), std::forward<Args_>(args)...));
        auto backup(inner.get());
        inner_ = std::move(inner);
        return backup;
    }
};

template <typename Base_, typename Inner_ = Pump, typename Drain_ = BufferDrain>
class Sink final :
    public Base_,
    public Sunk<Inner_, Drain_>
{
  private:
    Inner_ *Inner() override {
        auto inner(this->inner_.get());
        orc_insist_(inner != nullptr, typeid(Inner_).name() << " " << typeid(Base_).name() << "::Inner() == nullptr");
        return inner;
    }

    Drain_ *Gave() override {
        return this;
    }

  public:
    using Base_::Base_;

    ~Sink() override {
        if (Verbose)
            Log() << "~Sink<" << typeid(Base_).name() << ", " << typeid(Inner_).name() << ">()" << std::endl;
    }
};

}

#endif//ORCHID_LINK_HPP
