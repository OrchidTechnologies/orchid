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


#ifndef ORCHID_EVENT_HPP
#define ORCHID_EVENT_HPP

#include <cppcoro/async_manual_reset_event.hpp>
#include <cppcoro/single_consumer_event.hpp>

#include "spawn.hpp"

namespace orc {

template <typename Type_>
class Transfer_ {
  protected:
    cppcoro::async_manual_reset_event ready_;
    Maybe<Type_> maybe_;

  public:
    operator bool() noexcept {
        return ready_.is_set();
    }

    void operator ()(const std::exception_ptr &error) noexcept {
        maybe_(error);
        ready_.set();
    }
};

template <typename Type_>
class Transfer :
    public Transfer_<Type_>
{
  public:
    void operator =(Type_ &&value) noexcept {
        this->maybe_ = std::move(value);
        this->ready_.set();
    }

    task<void> operator ()(Task<Type_> &&code) noexcept { try {
        operator =(co_await std::move(code));
    } catch (...) {
        operator ()(std::current_exception());
    } }

    task<Type_> operator *() {
        co_await this->ready_;
        co_await Schedule();
        co_return *std::move(this->maybe_);
    }
};

template <>
class Transfer<void> :
    public Transfer_<void>
{
  public:
    using Transfer_<void>::operator ();

    void operator ()() noexcept {
        this->maybe_();
        this->ready_.set();
    }

    task<void> operator ()(Task<void> &&code) noexcept { try {
        co_await std::move(code);
        operator ()();
    } catch (...) {
        operator ()(std::current_exception());
    } }

    task<void> operator *() {
        co_await this->ready_;
        co_await Schedule();
        co_return *std::move(this->maybe_);
    }
};

typedef Transfer<void> Event;

}

#endif//ORCHID_EVENT_HPP
