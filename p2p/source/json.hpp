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


#ifndef ORCHID_JSON_HPP
#define ORCHID_JSON_HPP

#include <json/json.h>

#include "buffer.hpp"
#include "error.hpp"

namespace orc {

class Argument final {
  private:
    mutable Json::Value value_;

  public:
    Argument(Json::Value value) :
        value_(std::move(value))
    {
    }

    template <unsigned Bits_, boost::multiprecision::cpp_int_check_type Check_>
    Argument(const boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::unsigned_magnitude, Check_, void>> &value) :
        value_("0x" + value.str(0, std::ios::hex))
    {
    }

    Argument(unsigned value) :
        value_(value)
    {
    }

    Argument(nullptr_t) {
    }

    Argument(bool value) :
        value_(value)
    {
    }

    Argument(const char *value) :
        value_(value)
    {
    }

    Argument(const std::string &value) :
        value_(value)
    {
    }

    Argument(const Buffer &buffer) :
        value_(buffer.hex())
    {
    }

    Argument(std::initializer_list<Argument> args) :
        value_(Json::arrayValue)
    {
        int index(0);
        for (auto arg(args.begin()); arg != args.end(); ++arg)
            value_[index++] = std::move(arg->value_);
    }

    template <typename Type_>
    Argument(const std::vector<Type_> &args) :
        value_(Json::arrayValue)
    {
        int index(0);
        for (auto arg(args.begin()); arg != args.end(); ++arg)
            value_[index] = Argument(arg->value_);
    }

    Argument(std::map<std::string, Argument> args) :
        value_(Json::objectValue)
    {
        for (auto arg(args.begin()); arg != args.end(); ++arg)
            value_[arg->first] = std::move(arg->second);
    }

    operator Json::Value &&() && {
        return std::move(value_);
    }
};

typedef std::map<std::string, Argument> Multi;

inline std::string Unparse(Argument &&data) {
    Json::FastWriter writer;
    return writer.write(std::move(data));
}

inline Json::Value Parse(const std::string &data) {
    Json::Value result;
    Json::Reader reader;
    orc_assert(reader.parse(data, result, false));
    return result;
}

template <typename Type_>
struct Element;

#define orc_element(name) \
template <> \
struct Element<decltype(std::declval<Json::Value>().as ## name())> { \
static auto Get(const Json::Value &value, unsigned index) { \
    return value[index].as ## name(); \
} };

orc_element(Bool)
orc_element(Double)
orc_element(Float)
orc_element(Int)
orc_element(String)
orc_element(UInt)

template <typename... Elements_, size_t... Indices_>
std::tuple<Elements_...> Parse(const std::string &data, std::index_sequence<Indices_...>) {
    const auto array(Parse(data));
    return std::make_tuple<Elements_...>(Element<Elements_>::Get(array, Indices_)...);
}

template <typename... Elements_>
std::tuple<Elements_...> Parse(const std::string &data) {
    return Parse<Elements_...>(data, std::index_sequence_for<Elements_...>());
}

}

#endif//ORCHID_JSON_HPP
