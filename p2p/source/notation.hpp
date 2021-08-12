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


#ifndef ORCHID_NOTATION_HPP
#define ORCHID_NOTATION_HPP

#include <boost/json.hpp>
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

    Argument(uint64_t value) :
        value_([&]() {
#ifdef __APPLE__
            std::ostringstream data;
            data << "0x" << std::hex << value;
            return data.str();
#else
            std::string data;
            data.resize(18);
            const auto start(data.data());
            const auto end(start + data.size());
            start[0] = '0';
            start[1] = 'x';
            const auto result(std::to_chars(start + 2, end, value, 16));
            orc_assert(result.ec == std::errc());
            data.resize(result.ptr - start);
            return data;
#endif
        }())
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
        for (const auto &arg : args)
            value_[index++] = std::move(Argument(arg).value_);
    }

    Argument(std::map<std::string, Argument> args) :
        value_(Json::objectValue)
    {
        for (auto arg(args.begin()); arg != args.end(); ++arg)
            value_[arg->first] = std::move(arg->second);
    }

    template <typename Type_>
    Argument(std::optional<Type_> arg) :
        value_(arg ? std::move(Argument(std::move(*arg)).value_) : Json::nullValue)
    {
    }

    operator Json::Value &&() && {
        return std::move(value_);
    }
};

typedef std::map<std::string, Argument> Multi;

inline std::string Unparse(Argument &&data) {
    Json::StreamWriterBuilder builder;
    builder["indentation"] = "";
    return Json::writeString(builder, std::move(data));
}

inline Json::Value Parse(const std::string &data) { orc_block({
    Json::Value result;
    Json::Reader reader;
    orc_assert(reader.parse(data, result, false));
    return result;
}, "parsing " << data); }

inline std::string UnparseB(const boost::json::object &data) {
    return boost::json::serialize(data);
}

inline boost::json::value ParseB(const std::string &data) { orc_block({
    return boost::json::parse(data);
}, "parsing " << data); }

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

template <typename Type_>
inline std::enable_if_t<std::is_integral_v<Type_>, std::string> Str(const Type_ &value) {
    return std::to_string(value); }
inline std::string Str(const boost::string_view &value) {
    return std::string(value); }
inline std::string Str(const boost::json::string &value) {
    return Str(value.operator boost::string_view()); }
inline std::string Str(const boost::json::value &value) {
    return Str(value.as_string()); }

// XXX: this is dangerous and needs Fit
template <typename Type_>
Type_ Num(const boost::json::value &value) {
    switch (value.kind()) {
        case boost::json::kind::int64:
            return Type_(value.get_int64());
        case boost::json::kind::uint64:
            return Type_(value.get_uint64());
        case boost::json::kind::double_:
            return Type_(value.get_double());
        default: orc_assert(false);
    }
}

}

#endif//ORCHID_NOTATION_HPP
