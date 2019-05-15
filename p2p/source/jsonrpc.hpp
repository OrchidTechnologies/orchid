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
#include "http.hpp"
#include "task.hpp"

namespace orc {

// XXX: none of this is REMOTELY efficient

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

    Nested(Nested &&rhs) :
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

std::string Implode(Nested value);

class Argument final {
  private:
    mutable Json::Value value_;

  public:
    Argument(uint256_t value) :
        value_("0x" + value.str(0, std::ios::hex))
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
        value_([&]() {
            std::ostringstream value;
            value << "0x" << std::hex << std::setfill('0');
            buffer.each([&](const Region &region) {
                auto data(region.data());
                for (size_t i(0), e(region.size()); i != e; ++i)
                    value << std::setw(2) << unsigned(uint8_t(data[i]));
                return true;
            });
            return value.str();
        }())
    {
    }

    Argument(std::initializer_list<Argument> args) {
        int index(0);
        for (auto arg(args.begin()); arg != args.end(); ++arg)
            value_[index++] = std::move(arg->value_);
    }

    Argument(std::map<std::string, Argument> args) {
        for (auto arg(args.begin()); arg != args.end(); ++arg)
            value_[std::move(arg->first)] = std::move(arg->second);
    }

    operator Json::Value &&() && {
        return std::move(value_);
    }
};

typedef std::map<std::string, Argument> Map;

class Endpoint final {
  private:
    const URI uri_;

  public:
    Endpoint(URI uri) :
        uri_(std::move(uri))
    {
    }

    task<Json::Value> operator ()(const std::string &method, Argument args);
};

}

#endif//ORCHID_JSONRPC_HPP
