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

#include <asio/experimental/co_spawn.hpp>
#include <asio/experimental/detached.hpp>

#include <boost/asio/async_result.hpp>
#include <boost/asio/io_context.hpp>

#include <iostream>

#include <asio.hpp>
#include "task.hpp"

namespace orc {

template <typename Type_>
using Awaitable = asio::experimental::awaitable<Type_, asio::io_context::executor_type>;

boost::asio::io_context &Context();
std::thread &Thread();

template <typename Type_, typename... Args_>
class Baton;

template <typename Type_>
class Baton<Type_, asio::error_code> {
  public:
    typedef void Value;
    asio::error_code error_;

  public:
    task<void> get() const {
        if (error_) {
            auto error(error_);
            co_await Schedule();
            throw error;
        }
    }

    Type_ set(const asio::error_code &error) {
        error_ = error;
    }
};

template <typename Type_, typename Value_>
class Baton<Type_, asio::error_code, Value_> :
    public Baton<Type_, asio::error_code>
{
  public:
    typedef Value_ Value;
    Value value_;

  public:
    task<Value> get() const {
        co_await Baton<Type_, asio::error_code>::get();
        auto value(std::move(value_));
        co_await Schedule();
        co_return std::move(value);
    }

    Type_ set(const asio::error_code &error, Value &&value) {
        Baton<Type_, asio::error_code>::set(error);
        value_ = std::move(value);
    }
};

struct Token {
    cppcoro::async_manual_reset_event event_;
    void *baton_;

    template <typename Type_, typename... Args_>
    auto get() -> task<typename Baton<Type_, Args_...>::Value> {
        co_await event_;
        co_return co_await reinterpret_cast<Baton<Type_, Args_...> *>(baton_)->get();
    }

    template <typename Type_, typename... Args_>
    void set(Args_ &&... args) {
        reinterpret_cast<Baton<Type_, Args_...> *>(baton_)->set(std::forward<Args_>(args)...);
        event_.set();
    }
};

template <typename Type_, typename... Args_>
class Handler {
  public:
    Token *token_;
    Baton<Type_, Args_...> baton_;

  public:
    Handler(orc::Token &&token) :
        token_(&token)
    {
        token_->baton_ = &baton_;
    }

    Handler(orc::Handler<Type_, Args_...> &&rhs) noexcept :
        token_(rhs.token_)
    {
        token_->baton_ = &baton_;
        rhs.token_ = nullptr;
    }

    void operator()(Args_... args) {
        token_->set<Type_, Args_...>(std::forward<Args_>(args)...);
    }
};

}

namespace boost {
namespace asio {

template <typename Type_, typename... Args_>
class async_result<orc::Token, Type_ (Args_...)> {
  public:
    typedef orc::Handler<Type_, Args_...> completion_handler_type;

  private:
    orc::Token *token_;

  public:
    async_result(completion_handler_type &handler) :
        token_(handler.token_)
    {
    }

    typedef task<typename orc::Baton<Type_, Args_...>::Value> return_type;

    return_type get() {
        return token_->get<Type_, Args_...>();
    }
};

} }

#endif//ORCHID_BATON_HPP
