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


#ifndef ORCHID_ENDPOINT_HPP
#define ORCHID_ENDPOINT_HPP

#include "crypto.hpp"
#include "jsonrpc.hpp"
#include "locator.hpp"
#include "origin.hpp"

namespace orc {

struct Block {
    const uint256_t number_;
    const uint256_t state_;
    const uint256_t timestamp_;

    Block(Json::Value &&value);
};

struct Receipt final {
    const bool status_;
    const Address contract_;
    const uint256_t gas_;

    Receipt(Json::Value &&value);
};

struct Account final {
    const uint256_t nonce_;
    const uint256_t balance_;
    const uint256_t storage_;
    const uint256_t code_;

    Account(const Block &block, const Json::Value &value);
};

class Endpoint final {
  private:
    template <typename Type_>
    struct Result_ final {
        typedef uint256_t type;
    };

    const S<Origin> origin_;
    const Locator locator_;

    uint256_t Get(int index, const Json::Value &storages, const Region &root, const uint256_t &key) const;

    template <int Offset_, int Index_, typename Result_, typename... Args_>
    void Get(Result_ &result, const Json::Value &storages, const Region &root) const {
    }

    template <int Offset_, int Index_, typename Result_, typename... Args_>
    void Get(Result_ &result, const Json::Value &storages, const Region &root, const uint256_t &key, Args_ &&...args) const {
        std::get<Offset_ + Index_>(result) = Get(Index_, storages, root, key);
        Get<Offset_, Index_ + 1>(result, storages, root, std::forward<Args_>(args)...);
    }

  public:
    Endpoint(S<Origin> origin, Locator locator) :
        origin_(std::move(origin)),
        locator_(std::move(locator))
    {
    }

    task<Json::Value> operator ()(const std::string &method, Argument args) const;

    task<uint256_t> Chain() const;
    task<uint256_t> Latest() const;
    task<Block> Header(const Argument &number) const;
    task<uint256_t> Balance(const Address &address) const;
    task<std::optional<Receipt>> operator ()(const Bytes32 &transaction) const;

    task<Brick<65>> Sign(const Address &signer, const Buffer &data) const;
    task<Brick<65>> Sign(const Address &signer, const std::string &password, const Buffer &data) const;

    task<Address> Resolve(const Argument &number, const std::string &name) const;

    template <typename... Args_>
    task<std::tuple<Account, typename Result_<Args_>::type...>> Get(const Block &block, const Address &contract, std::nullptr_t, Args_ &&...args) const {
        const auto proof(co_await operator ()("eth_getProof", {contract, {std::forward<Args_>(args)...}, block.number_}));
        std::tuple<Account, typename Result_<Args_>::type...> result(Account(block, proof));
        Number<uint256_t> root(proof["storageHash"].asString());
        Get<1, 0>(result, proof["storageProof"], root, std::forward<Args_>(args)...);
        co_return result;
    }

    template <typename... Args_>
    task<std::tuple<typename Result_<Args_>::type...>> Get(const Block &block, const Address &contract, const uint256_t &storage, Args_ &&...args) const {
        const auto proof(co_await operator ()("eth_getProof", {contract, {std::forward<Args_>(args)...}, block.number_}));
        std::tuple<typename Result_<Args_>::type...> result;
        Number<uint256_t> root(proof["storageHash"].asString());
        orc_assert(storage == root.num<uint256_t>());
        Get<0, 0>(result, proof["storageProof"], root, std::forward<Args_>(args)...);
        co_return result;
    }

    template <typename... Args_>
    task<std::tuple<Account, std::vector<uint256_t>>> Get(const Block &block, const Address &contract, const std::vector<uint256_t> &args) const {
        const auto proof(co_await operator ()("eth_getProof", {contract, {std::forward<Args_>(args)...}, block.number_}));
        std::tuple<Account, std::vector<uint256_t>> result(Account(block, proof));
        Number<uint256_t> root(proof["storageHash"].asString());
        auto storages(proof["storageProof"]);
        for (unsigned i(0); i != args.size(); ++i)
            std::get<1>(result).emplace_back(Get(i, storages, root, args[i]));
        co_return result;
    }

    task<Bytes32> Send(const Address &from, const Address &contract, const uint256_t &gas, const Buffer &data) const {
        co_return Bless((co_await operator ()("eth_sendTransaction", {Multi{
            {"from", from},
            {"to", contract},
            {"gas", gas},
            {"data", data},
        }})).asString());
    }

    task<Bytes32> Send(const Address &from, const Address &contract, const uint256_t &gas, const uint256_t &value, const Buffer &data) const {
        co_return Bless((co_await operator ()("eth_sendTransaction", {Multi{
            {"from", from},
            {"to", contract},
            {"gas", gas},
            {"value", value},
            {"data", data},
        }})).asString());
    }

    task<Bytes32> Send(const Argument &arg) const {
        co_return Bless((co_await operator ()("eth_sendTransaction",
            arg
        )).asString());
    }
};

template <typename Result_, typename... Args_>
class Selector final :
    public Region
{
  private:
    const std::string name_;
    const uint32_t value_;

    template <bool Comma_, typename... Rest_>
    struct Args;

    template <bool Comma_, typename Next_, typename... Rest_>
    struct Args<Comma_, Next_, Rest_...> {
    static void Write(std::ostringstream &signature) {
        if (Comma_)
            signature << ',';
        Coded<Next_>::Name(signature);
        Args<true, Rest_...>::Write(signature);
    } };

    template <bool Comma_>
    struct Args<Comma_> {
    static void Write(std::ostringstream &signature) {
    } };

  public:
    Selector(uint32_t value) :
        name_([&]() {
            std::ostringstream signature;
            signature << "0x" << std::hex << std::setfill('0') << std::setw(8) << value;
            return signature.str();
        }()),
        value_(boost::endian::native_to_big(value))
    {
    }

    Selector(const std::string &name) :
        name_([&]() {
            std::ostringstream signature;
            signature << name << '(';
            Args<false, Args_...>::Write(signature);
            signature << ')';
            return signature.str();
        }()),
        value_(boost::endian::native_to_big(Hash(name_).template Clip<4>().template num<uint32_t>()))
    {
    }

    const uint8_t *data() const override {
        return reinterpret_cast<const uint8_t *>(&value_);
    }

    size_t size() const override {
        return sizeof(value_);
    }

    const std::string &Name() const {
        return name_;
    }

    Builder operator ()(const Args_ &...args) const {
        Builder builder;
        builder += *this;
        Coder<Args_...>::Encode(builder, std::forward<const Args_>(args)...);
        return builder;
    }

    auto Decode(const Buffer &buffer) {
        auto [tag, window] = Take<Number<uint32_t>, Window>(buffer);
        orc_assert(tag == *this);
        const auto result(Coded<std::tuple<Args_...>>::Decode(window));
        window.Stop();
        return result;
    }

    task<Result_> Call(const Endpoint &endpoint, const Argument &number, const Address &contract, const uint256_t &gas, const Args_ &...args) const { orc_block({
        Builder builder;
        Coder<Args_...>::Encode(builder, std::forward<const Args_>(args)...);
        auto data(Bless((co_await endpoint("eth_call", {Multi{
            {"to", contract},
            {"gas", gas},
            {"data", Tie(*this, builder)},
        }, number})).asString()));
        Window window(data);
        auto result(Coded<Result_>::Decode(window));
        window.Stop();
        co_return std::move(result);
    }, "calling " << Name()); }

    task<Result_> Call(const Endpoint &endpoint, const Address &from, const Argument &number, const Address &contract, const uint256_t &gas, const Args_ &...args) const { orc_block({
        Builder builder;
        Coder<Args_...>::Encode(builder, std::forward<const Args_>(args)...);
        auto data(Bless((co_await endpoint("eth_call", {Multi{
            {"from", from},
            {"to", contract},
            {"gas", gas},
            {"data", Tie(*this, builder)},
        }, number})).asString()));
        Window window(data);
        auto result(Coded<Result_>::Decode(window));
        window.Stop();
        co_return std::move(result);
    }, "calling " << Name()); }

    task<Bytes32> Send(const Endpoint &endpoint, const Address &from, const std::string &password, const Address &contract, const uint256_t &gas, const Args_ &...args) const { orc_block({
        Builder builder;
        Coder<Args_...>::Encode(builder, std::forward<const Args_>(args)...);
        auto transaction(Bless((co_await endpoint("personal_sendTransaction", {Multi{
            {"from", from},
            {"to", contract},
            {"gas", gas},
            {"data", Tie(*this, builder)},
        }, password})).asString()));
        co_return std::move(transaction);
    }, "sending " << Name()); }

    task<Bytes32> Send(const Endpoint &endpoint, const Address &from, const std::string &password, const Address &contract, const uint256_t &gas, const uint256_t &price, const Args_ &...args) const { orc_block({
        Builder builder;
        Coder<Args_...>::Encode(builder, std::forward<const Args_>(args)...);
        auto transaction(Bless((co_await endpoint("personal_sendTransaction", {Multi{
            {"from", from},
            {"to", contract},
            {"gas", gas},
            {"gasPrice", price},
            {"data", Tie(*this, builder)},
        }, password})).asString()));
        co_return std::move(transaction);
    }, "sending " << Name()); }
};

template <typename... Args_>
class Constructor final {
  public:
    task<Bytes32> Send(const Endpoint &endpoint, const Address &from, const uint256_t &gas, const Buffer &data, const Args_ &...args) const { orc_block({
        Builder builder;
        Coder<Args_...>::Encode(builder, std::forward<const Args_>(args)...);
        co_return co_await endpoint.Send({Multi{
            {"from", from},
            {"gas", gas},
            {"data", Tie(data, builder)},
        }});
    }, "constructing"); }
};

}

#endif//ORCHID_ENDPOINT_HPP
