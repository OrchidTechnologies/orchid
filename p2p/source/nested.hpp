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


#ifndef ORCHID_NESTED_HPP
#define ORCHID_NESTED_HPP

#include <iostream>
#include <string>
#include <vector>

#include "buffer.hpp"
#include "integer.hpp"
#include "jsonrpc.hpp"

namespace orc {

// XXX: none of this is REMOTELY efficient
// XXX: this predates Buffer and makes no sense

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
        scalar_(true)
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
        value_(value == 0 ? 0 : 1, value)
    {
    }

    Nested(uint64_t value) :
        scalar_(true)
    {
        Number<uint64_t> number(value);
        auto span(number.span());
        while (span.size() != 0 && span[0] == 0)
            ++span;
        value_ = {reinterpret_cast<const char *>(span.data()), span.size()};
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

    template <typename Type_>
    Nested(std::optional<Type_> value) :
        Nested()
    {
        if (value)
            operator =(std::move(*value));
    }

    Nested(const Buffer &buffer) :
        Nested(buffer.str())
    {
    }

    template <unsigned Bits_, boost::multiprecision::cpp_int_check_type Check_>
    Nested(const boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::unsigned_magnitude, Check_, void>> &value) :
        scalar_(true),
        value_([&]() -> std::string {
            Number<boost::multiprecision::number<boost::multiprecision::backends::cpp_int_backend<Bits_, Bits_, boost::multiprecision::unsigned_magnitude, Check_, void>>> data(value);
            auto span(data.span());
            while (span.size() != 0 && span[0] == 0)
                ++span;
            return {reinterpret_cast<const char *>(span.data()), span.size()};
        }())
    {
    }

    Nested(const Address &value) :
        Nested(value.buf())
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

    Nested(const Nested &rhs) = default;
    Nested &operator =(Nested &&rhs) = default;

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

Nested Explode(Window &window);
Nested Explode(Window &&window);

std::string Implode(const Nested &nested);

}

#endif//ORCHID_NESTED_HPP
