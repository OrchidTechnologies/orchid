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
#include "crypto.hpp"
#include "http.hpp"
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

    Argument(std::map<std::string, Argument> args) :
        value_(Json::objectValue)
    {
        for (auto arg(args.begin()); arg != args.end(); ++arg)
            value_[std::move(arg->first)] = std::move(arg->second);
    }

    operator Json::Value &&() && {
        return std::move(value_);
    }
};

typedef std::map<std::string, Argument> Map;

class Proven final {
  private:
    uint256_t balance_;

  public:
    Proven(Json::Value value) :
        balance_(value["balance"].asString())
    {
    }

    const uint256_t &Balance() {
        return balance_;
    }
};

template <typename Type_>
struct Result final {
    typedef uint256_t type;
};

class Selector final :
    public Region
{
  private:
    uint32_t value_;

  public:
    Selector(uint32_t value) :
        value_(boost::endian::native_to_big(value))
    {
    }

    Selector(const char *data, size_t size) :
        Selector(Hash(Subset(data, size)).Clip<4>().num<uint32_t>())
    {
    }

    Selector(const char *signature) :
        Selector(signature, strlen(signature))
    {
    }

    Selector(const std::string &signature) :
        Selector(signature.data(), signature.size())
    {
    }

    const uint8_t *data() const override {
        return reinterpret_cast<const uint8_t *>(&value_);
    }

    size_t size() const override {
        return sizeof(value_);
    }
};

class Endpoint final {
  private:
    const URI uri_;

    template <int Index_, typename Result_, typename... Args_>
    void Get(Result_ &result, Json::Value &storage) {
    }

    template <int Index_, typename Result_, typename... Args_>
    void Get(Result_ &result, Json::Value &storage, const uint256_t &key, Args_ &&...args) {
        auto proof(storage[Index_]);
        orc_assert(uint256_t(proof["key"].asString()) == key);
        uint256_t value(proof["value"].asString());
        std::get<Index_ + 1>(result) = value;
        Get<Index_ + 1>(result, storage, std::forward<Args_>(args)...);
    }

  public:
    Endpoint(URI uri) :
        uri_(std::move(uri))
    {
    }

    task<Json::Value> operator ()(const std::string &method, Argument args);

    task<uint256_t> Block() {
        co_return uint256_t((co_await operator ()("eth_blockNumber", {})).asString());
    }

    template <typename... Args_>
    task<Beam> Call(const Argument &block, uint256_t account, const Selector &selector, Args_ &&...args) {
        co_return Bless((co_await operator ()("eth_call", {Map{
            {"to", account},
            {"data", Tie(selector, std::forward<Args_>(args)...)},
        }, block})).asString());
    }

    template <typename... Args_>
    task<std::tuple<Proven, typename Result<Args_>::type...>> Get(const Argument &block, uint256_t account, Args_ &&...args) {
        auto proof(co_await operator ()("eth_getProof", {account, {std::forward<Args_>(args)...}, block}));
        std::tuple<Proven, typename Result<Args_>::type...> result(proof);
        Get<0>(result, proof["storageProof"], std::forward<Args_>(args)...);
        co_return result;
    }
};

}

#endif//ORCHID_JSONRPC_HPP
