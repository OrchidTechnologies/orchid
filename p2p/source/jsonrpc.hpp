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


#ifndef ORCHID_JSONRPC_HPP
#define ORCHID_JSONRPC_HPP

#include <string>

#include <json/json.h>

#include "buffer.hpp"
#include "task.hpp"

namespace orc {

// XXX: none of this is REMOTELY efficient

typedef boost::multiprecision::number<boost::multiprecision::cpp_int_backend<160, 160, boost::multiprecision::unsigned_magnitude, boost::multiprecision::unchecked, void>> uint160_t;

class Nested {
  protected:
    bool scalar_;
    mutable std::string value_;
    mutable std::vector<Nested> array_;

  private:
    static void enc(std::string &data, unsigned length);
    static void enc(std::string &data, unsigned length, uint8_t offset);

  public:
    Nested() :
        scalar_(false)
    {
    }

    Nested(bool scalar, std::string value, std::vector<Nested> array) :
        scalar_(scalar),
        value_(std::move(value)),
        array_(std::move(array))
    {
    }

    Nested(uint8_t value) :
        scalar_(true),
        value_(1, char(value))
    {
    }

    Nested(std::string value) :
        scalar_(true),
        value_(std::move(value))
    {
    }

    Nested(const char *value) :
        Nested(std::string(value))
    {
    }

    Nested(const Buffer &buffer) :
        Nested(buffer.str())
    {
    }

    Nested(std::initializer_list<Nested> list) :
        scalar_(false)
    {
        for (auto nested(list.begin()); nested != list.end(); ++nested)
            array_.emplace_back(nested->scalar_, std::move(nested->value_), std::move(nested->array_));
    }

    Nested(Nested &&rhs) noexcept :
        scalar_(rhs.scalar_),
        value_(std::move(rhs.value_)),
        array_(std::move(rhs.array_))
    {
    }

    bool scalar() const {
        return scalar_;
    }

    size_t size() const {
        orc_assert(!scalar_);
        return array_.size();
    }

    const Nested &operator [](unsigned i) const {
        orc_assert(!scalar_);
        orc_assert(i < size());
        return array_[i];
    }

    Subset buf() const {
        orc_assert(scalar_);
        return Subset(value_);
    }

    const std::string &str() const {
        orc_assert(scalar_);
        return value_;
    }

    uint256_t num() const {
        orc_assert(scalar_);
        uint256_t value;
        if (value_.empty())
            value = 0;
        else
            boost::multiprecision::import_bits(value, value_.rbegin(), value_.rend(), 8, false);
        return value;
    }

    void enc(std::string &data) const;
};

std::ostream &operator <<(std::ostream &out, const Nested &value);

class Explode final :
    public Nested
{
  public:
    Explode(Window &window);
    Explode(Window &&window);
};

std::string Implode(Nested nested);

class Address :
    public uint160_t
{
  public:
    using uint160_t::uint160_t;

    Address(uint160_t &&value) :
        uint160_t(std::move(value))
    {
    }
};

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

    Argument(const Address &address) :
        Argument(Number<uint160_t>(address))
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

typedef std::map<std::string, Argument> Map;

typedef Beam Bytes;
typedef Brick<32> Bytes32;

template <typename Type_, typename Enable_ = void>
struct Coded;

template <typename... Args_>
struct Coder;

template <>
struct Coder<> {
static void Encode(Builder &builder) {
} };

template <typename Type_, typename... Args_>
struct Coder<Type_, Args_...> {
static void Encode(Builder &builder, const Type_ &value, const Args_ &...args) {
    Coded<Type_>::Encode(builder, value);
    Coder<Args_...>::Encode(builder, args...);
} };

template <bool Sign_, size_t Size_, typename Type_>
struct Numeric;

template <size_t Size_, typename Type_>
struct Numeric<false, Size_, Type_> {
    static Type_ Decode(Window &window) {
        window.Skip(32 - Size_);
        Brick<Size_> brick;
        window.Take(brick);
        return brick.template num<Type_>();
    }

    static void Encode(Builder &builder, const Type_ &value) {
        builder += Number<uint256_t>(value);
    }
};

// XXX: these conversions only just barely work
template <size_t Size_, typename Type_>
struct Numeric<true, Size_, Type_> {
    static Type_ Decode(Window &window) {
        Brick<32> brick;
        window.Take(brick);
        return brick.template num<uint256_t>().convert_to<Type_>();
    }

    static void Encode(Builder &builder, const Type_ &value) {
        builder += Number<uint256_t>(value, signbit(value) ? 0xff : 0x00);
    }
};

template <typename Type_>
struct Coded<Type_, typename std::enable_if<std::is_unsigned<Type_>::value>::type> :
    public Numeric<false, sizeof(Type_), Type_>
{
    static void Name(std::ostringstream &signature) {
        signature << "uint" << std::dec << sizeof(Type_) * 8;
    }
};

template <typename Type_>
struct Coded<Type_, typename std::enable_if<std::is_signed<Type_>::value>::type> :
    public Numeric<true, sizeof(Type_), Type_>
{
    static void Name(std::ostringstream &signature) {
        signature << "int" << std::dec << sizeof(Type_) * 8;
    }
};

template <unsigned Bits_, boost::multiprecision::cpp_int_check_type Check_>
struct Coded<boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::unsigned_magnitude, Check_, void>>, typename std::enable_if<Bits_ % 8 == 0>::type> :
    public Numeric<false, (Bits_ >> 3), boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::unsigned_magnitude, Check_, void>>>
{
    static void Name(std::ostringstream &signature) {
        signature << "uint" << std::dec << Bits_;
    }
};

/*template <unsigned Bits_, boost::multiprecision::cpp_int_check_type Check_>
struct Coded<boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::signed_magnitude, Check_, void>>, typename std::enable_if<Bits_ % 8 == 0>::type> :
    public Numeric<true, (Bits_ >> 3), boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::signed_magnitude, Check_, void>>>
{
    static void Name(std::ostringstream &signature) {
        signature << "int" << std::dec << Bits_;
    }
};*/

template <>
struct Coded<Address, void> {
    static void Name(std::ostringstream &signature) {
        signature << "address";
    }

    static Address Decode(Window &window) {
        return Coded<uint160_t>::Decode(window);
    }

    static void Encode(Builder &builder, const Address &value) {
        return Coded<uint160_t>::Encode(builder, value);
    }
};

template <size_t Size_>
struct Coded<Brick<Size_>, typename std::enable_if<Size_ == 32>::type> {
    static void Name(std::ostringstream &signature) {
        signature << "bytes" << std::dec << Size_;
    }

    static Bytes32 Decode(Window &window) {
        Brick<Size_> value;
        window.Take(value);
        return value;
    }

    static void Encode(Builder &builder, const Brick<Size_> &data) {
        builder += data;
    }
};

template <>
struct Coded<Beam, void> {
    static void Name(std::ostringstream &signature) {
        signature << "bytes";
    }

    static Beam Decode(Window &window) {
        auto size(Coded<uint256_t>::Decode(window).convert_to<size_t>());
        auto data(window.Take(size));
        window.Skip(31 - (size + 31) % 32);
        return data;
    }

    static void Encode(Builder &builder, const Beam &data) {
        auto size(data.size());
        Coded<uint256_t>::Encode(builder, size);
        builder += data;
        Beam pad(31 - (size + 31) % 32);
        memset(pad.data(), 0, pad.size());
        builder += std::move(pad);
    }
};

// XXX: provide a more complete implementation

template <typename Type_>
struct Coded<std::vector<Type_>, void> {
    static void Name(std::ostringstream &signature) {
        Coded<Type_>::Name(signature);
        signature << "[]";
    }

    static void Encode(Builder &builder, const std::vector<Type_> &values) {
        Coded<uint256_t>::Encode(builder, values.size());
        for (const auto &value : values)
            Coded<Type_>::Encode(builder, value);
    }
};

template <>
struct Coded<std::tuple<uint256_t, Bytes>, void> {
    static std::tuple<uint256_t, Bytes> Decode(Window &window) {
        std::tuple<uint256_t, Bytes> value;
        std::get<0>(value) = Coded<uint256_t>::Decode(window);
        orc_assert(Coded<uint256_t>::Decode(window) == 0x40);
        std::get<1>(value) = Coded<Bytes>::Decode(window);
        return value;
    }
};

}

#endif//ORCHID_JSONRPC_HPP
