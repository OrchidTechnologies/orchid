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


#ifndef ORCHID_BATON_HPP
#define ORCHID_BATON_HPP

#include <cppcoro/async_manual_reset_event.hpp>

#include <asio/co_spawn.hpp>
#include <asio/detached.hpp>

#include <boost/asio/async_result.hpp>
#include <boost/asio/io_context.hpp>

#include <iostream>

#include <asio.hpp>
#include "error.hpp"
#include "task.hpp"

namespace orc {

asio::io_context &Context();
std::thread &Thread();

template <typename Type_, typename... Values_>
class Baton;

template <>
class Baton<void> {
  private:
    cppcoro::async_manual_reset_event ready_;

  public:
    Baton() = default;

    Baton(const Baton<void> &) = delete;
    Baton(Baton<void> &&) = delete;

    void set() {
        ready_.set();
    }

    task<void> get() {
        co_await ready_;
        co_await Schedule();
    }
};

template <>
class Baton<void, asio::error_code> :
    public Baton<void>
{
  private:
    asio::error_code error_;

  public:
    void set(const asio::error_code &error) {
        error_ = error;
        Baton<void>::set();
    }

    task<void> get() {
        co_await Baton<void>::get();
        if (error_)
            throw asio::system_error(error_);
    }
};

template <typename Value_>
class Baton<void, asio::error_code, Value_> :
    public Baton<void, asio::error_code>
{
  private:
    Value_ value_;

  public:
    void set(const asio::error_code &error, Value_ &&value) {
        value_ = std::move(value);
        Baton<void, asio::error_code>::set(error);
    }

    task<Value_> get() {
        co_await Baton<void, asio::error_code>::get();
        co_return std::move(value_);
    }
};

struct Token {
};

template <typename Type_, typename... Values_>
class Handler {
  public:
    Baton<Type_, Values_...> *baton_;

  public:
    Handler(Baton<Type_, Values_...> *baton) :
        baton_(baton)
    {
    }

    void operator()(Values_... values) {
        baton_->set(std::move(values)...);
    }
};

}

namespace boost {
namespace asio {

template <typename Type_, typename... Values_>
struct async_result<orc::Token, Type_ (Values_...)> {
    async_result() = delete;

    typedef decltype(std::declval<orc::Baton<Type_, Values_...>>().get()) return_type;

    template <typename Initiation_, typename... Args_>
    static return_type initiate(Initiation_ initiation, orc::Token &&, Args_... args) {
        orc::Baton<Type_, Values_...> baton;
        std::move(initiation)(orc::Handler<Type_, Values_...>(&baton), std::move(args)...);
        co_return co_await baton.get();
    }
};

} }

#endif//ORCHID_BATON_HPP
