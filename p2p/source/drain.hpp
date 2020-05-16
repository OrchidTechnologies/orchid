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


#ifndef ORCHID_DRAIN_HPP
#define ORCHID_DRAIN_HPP

#include "valve.hpp"

namespace orc {

class Basin {
  public:
    // XXX: make this take an std::exception_ptr
    virtual void Stop(const std::string &error = std::string()) noexcept = 0;
};

template <typename Type_>
class Drain :
    public Basin
{
  public:
    virtual void Land(Type_ data) = 0;
};

template <typename Type_>
class Sunken {
  protected:
    virtual Type_ &Inner() noexcept = 0;

    virtual task<void> Drop() noexcept = 0;

    task<void> Shut() {
        co_await Drop();
    }
};

template <typename Base_>
class Outer :
    private Base_
{
  public:
    using Base_::Inner;
};

template <typename Drain_, typename Inner_>
class Sunk {
  protected:
    U<Inner_> inner_;

    virtual Drain_ &Gave() noexcept = 0;

  public:
    bool Wired() noexcept {
        return inner_ != nullptr;
    }

    template <typename Type_, typename... Args_>
    Type_ &Wire(Args_ &&...args) noexcept(noexcept(Type_(Gave(), std::forward<Args_>(args)...))) {
        auto inner(std::make_unique<Type_>(Gave(), std::forward<Args_>(args)...));
        auto &backup(*inner);
        orc_insist(!Wired());
        inner_ = std::move(inner);
        return backup;
    }
};

template <typename Base_, typename Drain_, typename Inner_ = typename std::remove_reference<decltype(std::declval<Outer<Base_>>().Inner())>::type>
class Sink final :
    public Base_,
    public Sunk<Drain_, Inner_>
{
  private:
    Inner_ &Inner() noexcept override {
        const auto inner(this->inner_.get());
        orc_insist_(inner != nullptr, typeid(decltype(this->inner_.get())).name() << " " << typeid(Base_).name() << "::Inner() == nullptr");
        return *inner;
    }

    task<void> Drop() noexcept override {
        const auto inner(std::move(this->inner_));
        if (inner != nullptr)
            co_await inner->Shut();
    }

    Drain_ &Gave() noexcept override {
        return *this;
    }

  public:
    using Base_::Base_;

    Sink() {
        this->type_ = typeid(*this).name();
    }

    ~Sink() override {
        if (Verbose)
            Log() << "~BufferSink<" << typeid(Base_).name() << ">()" << std::endl;
        orc_insist_(this->inner_ == nullptr, typeid(decltype(this->inner_.get())).name() << " " << typeid(Base_).name() << "::Inner() != nullptr");
    }
};

}

#endif//ORCHID_DRAIN_HPP
