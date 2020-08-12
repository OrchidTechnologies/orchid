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


#ifndef ORCHID_HEAP_HPP
#define ORCHID_HEAP_HPP

#include <memory>
#include <string>

#include <quickjs.h>

#include "scope.hpp"

namespace orc {

template <typename Type_>
struct Free;

template <>
struct Free<JSRuntime> {
void operator ()(JSRuntime *value) {
    JS_FreeRuntime(value);
} };

template <>
struct Free<JSContext> {
void operator ()(JSContext *value) {
    JS_FreeContext(value);
} };

class Value {
  private:
    JSContext *context_;
    JSValue value_;

  public:
    Value(JSContext *context, JSValue value);

    ~Value() {
        JS_FreeValue(context_, value_);
    }

    operator JSValueConst() const {
        return value_;
    }

    operator JSValue() {
        return value_;
    }

    template <typename Type_>
    Type_ to();
};

class Heap {
  private:
    std::unique_ptr<JSRuntime, Free<JSRuntime>> runtime_;
    std::unique_ptr<JSContext, Free<JSContext>> context_;

  public:
    Heap() :
        runtime_(JS_NewRuntime()),
        context_(JS_NewContext(runtime_.get()))
    {
    }

    operator JSContext *() {
        return context_.get();
    }

    template <typename Type_>
    auto eval(const std::string &code, const std::function<Type_ ()> &fail) {
        Value value(context_.get(), JS_Eval(context_.get(), code.data(), code.size(), "", JS_EVAL_TYPE_GLOBAL));
        return JS_IsUndefined(value) ? fail() : value.to<Type_>();
    }

    template <typename Type_>
    auto eval(const std::string &code, const Type_ &fail) {
        return eval<Type_>(code, [&]() { return fail; });
    }

    template <typename Type_>
    auto eval(const std::string &code) {
        return eval<Type_>(code, [&]() -> Type_ { orc_assert(false); });
    }
};

template <>
inline void Value::to<void>() {
}

template <>
inline bool Value::to<bool>() {
    const auto value(JS_ToBool(context_, value_));
    orc_assert(value != -1);
    return value != 0;
}

template <>
inline double Value::to<double>() {
    double value;
    orc_assert(JS_ToFloat64(context_, &value, value_) == 0);
    return value;
}

template <>
inline std::string Value::to<std::string>() {
    size_t size;
    const auto data(JS_ToCStringLen(context_, &size, value_));
    orc_assert_(data != nullptr, Value(context_, JS_GetException(context_)).to<std::string>());
    _scope({ JS_FreeCString(context_, data); });
    return std::string(data, size);
}

inline Value::Value(JSContext *context, JSValue value) :
    context_(context),
    value_(value)
{
    orc_assert_(!JS_IsException(value), Value(context, JS_GetException(context)).to<std::string>());
}

}

#endif//ORCHID_HEAP_HPP
