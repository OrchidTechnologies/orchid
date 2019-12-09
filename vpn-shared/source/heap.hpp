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

#include <duktape.h>

namespace orc {

class Heap {
  private:
    duk_context *duk_;

  public:
    Heap() :
        duk_(duk_create_heap_default())
    {
    }

    ~Heap() {
        duk_destroy_heap(duk_);
    }

    operator duk_context *() {
        return duk_;
    }

    template <typename Type_>
    Type_ pop();

    template <typename Type_>
    Type_ pop(const Type_ &other);

    template <typename Type_>
    Type_ eval(const std::string &code) {
        duk_eval_string(duk_, code.c_str());
        return pop<Type_>();
    }

    template <typename Type_>
    Type_ eval(const std::string &code, const Type_ &other) {
        duk_eval_string(duk_, code.c_str());
        return pop<Type_>(other);
    }
};

template <>
inline void Heap::pop<void>() {
    duk_pop(duk_);
}

template <>
inline duk_bool_t Heap::pop<duk_bool_t>() {
    const auto value(duk_get_boolean(duk_, -1));
    duk_pop(duk_);
    return value;
}

template <>
inline duk_double_t Heap::pop<duk_double_t>() {
    const auto value(duk_get_number(duk_, -1));
    duk_pop(duk_);
    return value;
}

template <>
inline std::string Heap::pop<std::string>() {
    const std::string value(duk_get_string(duk_, -1));
    duk_pop(duk_);
    return value;
}

template <>
inline duk_bool_t Heap::pop<duk_bool_t>(const duk_bool_t &other) {
    const auto value(duk_get_boolean_default(duk_, -1, other));
    duk_pop(duk_);
    return value;
}

template <>
inline duk_double_t Heap::pop<duk_double_t>(const duk_double_t &other) {
    const auto value(duk_get_number_default(duk_, -1, other));
    duk_pop(duk_);
    return value;
}

template <>
inline std::string Heap::pop<std::string>(const std::string &other) {
    const std::string value(duk_get_string_default(duk_, -1, other.c_str()));
    duk_pop(duk_);
    return value;
}

}

#endif//ORCHID_HEAP_HPP
