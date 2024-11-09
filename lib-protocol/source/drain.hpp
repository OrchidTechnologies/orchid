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


#ifndef ORCHID_DRAIN_HPP
#define ORCHID_DRAIN_HPP

#include "valve.hpp"

namespace orc {

class Basin {
  public:
    virtual ~Basin() = default;

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
  public:
    virtual ~Sunken() = default;

  protected:
    virtual Type_ &Inner() noexcept = 0;

    virtual task<void> Drop() noexcept = 0;

    task<void> Shut() {
        co_await Drop();
    }
};

template <typename Super_>
class Outer :
    private Super_
{
  public:
    using Super_::Inner;
};

template <typename Drain_, typename Inner_>
class Sunk {
  protected:
    U<Inner_> inner_;

    virtual Drain_ &Gave() noexcept = 0;

  public:
    virtual ~Sunk() = default;

    bool Wired() noexcept {
        return inner_ != nullptr;
    }

    template <typename Type_, typename... Args_>
    Type_ &Wire(Args_ &&...args) noexcept(noexcept(Covered<Type_>(Gave(), std::forward<Args_>(args)...))) {
        auto inner(std::make_unique<Covered<Type_>>(Gave(), std::forward<Args_>(args)...));
        auto &backup(*inner);
        orc_insist(!Wired());
        inner_ = std::move(inner);
        return backup;
    }
};

template <typename Super_, typename Drain_, typename Inner_ = typename std::remove_reference_t<decltype(std::declval<Outer<Super_>>().Inner())>>
class Sink :
    public Super_,
    public Sunk<Drain_, Inner_>
{
  private:
    Inner_ &Inner() noexcept override {
        const auto inner(this->inner_.get());
        orc_insist_(inner != nullptr, typeid(decltype(this->inner_.get())).name() << " " << typeid(Super_).name() << "::Inner() == nullptr");
        return *inner;
    }

    task<void> Drop() noexcept override {
        if (const auto inner = std::move(this->inner_))
            co_await inner->Shut();
        else
            Super_::Stop(std::string());
    }

    Drain_ &Gave() noexcept override {
        return *this;
    }

  public:
    using Super_::Super_;

    ~Sink() override {
        if (Verbose)
            Log() << "~BufferSink<" << typeid(Super_).name() << ">()" << std::endl;
        orc_insist_(this->inner_ == nullptr, typeid(decltype(this->inner_.get())).name() << " " << typeid(Super_).name() << "::Inner() != nullptr");
    }
};

}

#endif//ORCHID_DRAIN_HPP
