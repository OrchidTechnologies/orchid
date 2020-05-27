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


#ifndef ORCHID_TASK_HPP
#define ORCHID_TASK_HPP

#include <variant>

#include <experimental/coroutine>

#include "error.hpp"

#define ORC_FIBER

namespace orc {

inline constexpr class {} co_optic;

class Fiber {
  private:
    Fiber *parent_;
    std::string name_;

  public:
    Fiber(Fiber *parent = nullptr) :
        parent_(parent)
    {
    }

    Fiber *Parent() {
        return parent_;
    }
};

template <typename Type_>
class Ready {
  private:
    Type_ value_;

  public:
    Ready(Type_ value) :
        value_(std::move(value))
    {
    }

    bool await_ready() noexcept {
        return true;
    }

    bool await_suspend(std::experimental::coroutine_handle<>) noexcept {
        return false;
    }

    auto await_resume() const {
        return std::move(value_);
    }
};

class Final {
  public:
    bool await_ready() noexcept {
        return false;
    }

    template <typename Promise_>
    auto await_suspend(std::experimental::coroutine_handle<Promise_> code) noexcept {
        return std::move(std::move(code).promise().code_);
    }

    void await_resume() noexcept {
    }
};

template <typename Value_>
class Task {
  public:
    class promise_type;

  private:
    std::experimental::coroutine_handle<promise_type> code_;

    class Awaitable {
      protected:
        std::experimental::coroutine_handle<promise_type> code_;

      public:
        Awaitable(std::experimental::coroutine_handle<promise_type> code) noexcept :
            code_(std::move(code))
        {
        }

        bool await_ready() noexcept {
	    return !code_ || code_.done();
        }

        template <typename Promise_>
        auto await_suspend(std::experimental::coroutine_handle<Promise_> code) noexcept {
            code_.promise().code_ = std::move(code);
            return code_;
        }
    };

  public:
    Task(std::experimental::coroutine_handle<promise_type> code) noexcept :
        code_(std::move(code))
    {
    }

    Task(Task &&task) noexcept :
        code_(std::move(task.code_))
    {
        task.code_ = nullptr;
    }

    ~Task() {
        if (code_ != nullptr)
            code_.destroy();
    }

    auto operator co_await() const && noexcept {
        typedef class : public Awaitable {
          public:
            using Awaitable::Awaitable;

            auto await_resume() const {
		return this->code_.promise()();
            }
        } Awaitable;

        return Awaitable(code_);
    }

    void Set(Fiber *fiber) {
        code_.promise().fiber_ = fiber;
    }
};

class Promise {
    template <typename Value_>
    friend class Task;

    friend class Final;

  private:
    std::experimental::coroutine_handle<> code_;

#ifdef ORC_FIBER
    Fiber *fiber_ = nullptr;
#endif

  public:
    auto initial_suspend() noexcept {
        return std::experimental::suspend_always(); }
    auto final_suspend() noexcept {
        return Final(); }

    template <typename Awaitable_>
    auto &&await_transform(Awaitable_ &&awaitable) {
        return std::forward<Awaitable_>(awaitable);
    }

    auto await_transform(decltype(co_optic)) {
        // NOLINTNEXTLINE (clang-analyzer-core.CallAndMessage)
        return Ready<Fiber *>(
#ifdef ORC_FIBER
            fiber_
#else
            nullptr
#endif
        );
    }

#ifdef ORC_FIBER
    template <typename Type_>
    auto &&await_transform(Task<Type_> &&task) {
        // NOLINTNEXTLINE (clang-analyzer-core.CallAndMessage)
        task.Set(fiber_);
        return std::forward<Task<Type_>>(task);
    }
#endif
};

template <typename Value_>
class Task<Value_>::promise_type :
    public Promise
{
  private:
    typedef std::variant<std::exception_ptr, Value_> Variant_;
    Variant_ variant_;

  public:
    auto get_return_object() noexcept {
        return Task<Value_>(std::experimental::coroutine_handle<promise_type>::from_promise(*this));
    }

    void unhandled_exception() noexcept {
        variant_.~Variant_();
        new (&variant_) Variant_(std::in_place_index_t<0>(), std::current_exception());
    }

    template <typename Type_, typename = std::enable_if_t<std::is_convertible_v<Type_ &&, Value_>>>
    void return_value(Type_ &&value) noexcept(std::is_nothrow_constructible_v<Value_, Type_ &&>) {
        variant_.~Variant_();
        new (&variant_) Variant_(std::in_place_index_t<1>(), std::forward<Type_>(value));
    }

    Value_ operator()() {
        // I would probably use std::get, but that doesn't work on iOS before 12.0
        if (auto *error = std::get_if<0>(&variant_))
            std::rethrow_exception(std::move(*error));
        return std::move(*std::get_if<1>(&variant_));
    }
};

template <>
class Task<void>::promise_type :
    public Promise
{
  private:
    std::exception_ptr error_;

  public:
    auto get_return_object() noexcept {
        return Task<void>(std::experimental::coroutine_handle<promise_type>::from_promise(*this));
    }

    void unhandled_exception() noexcept {
        error_ = std::current_exception();
    }

    void return_void() noexcept {
    }

    void operator()() {
        if (error_)
            std::rethrow_exception(error_);
    }
};

template <typename Value_>
using task = Task<Value_>;

}

#endif//ORCHID_TASK_HPP
