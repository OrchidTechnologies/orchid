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
#include "parallel.hpp"

namespace orc {

struct Receipt final {
    const uint64_t height_;
    const bool status_;
    const Address contract_;
    const uint64_t gas_;

    Receipt(Json::Value &&value);
};

struct Transaction {
    const uint256_t nonce_;
    const uint256_t bid_;
    const uint64_t gas_;
    const std::optional<Address> target_;
    const uint256_t amount_;
};

struct Record final :
    public Transaction
{
    const Bytes32 hash_;
    const Address from_;

    Record(const uint256_t &chain, const Json::Value &value);
};

struct Block {
    const uint64_t height_;
    const uint256_t state_;
    const uint64_t timestamp_;
    const uint64_t limit_;
    const Address miner_;
    const std::vector<Record> records_;

    Block(const uint256_t &chain, Json::Value &&value);
};

struct Account final {
    const uint256_t nonce_;
    const uint256_t balance_;
    const uint256_t storage_;
    const uint256_t code_;

    Account(const uint256_t &nonce, const uint256_t &balance);
    Account(const Block &block, const Json::Value &value);
};

struct Flags {
    bool insecure_ = false;
    bool verbose_ = false;
};

class Endpoint final {
  private:
    template <typename Type_>
    struct Result_ final {
        typedef uint256_t type;
    };

    const S<Origin> origin_;
    const Locator locator_;
    const Flags flags_;

    template <size_t Offset_, int Index_, typename Result_, typename Hypothesis_, size_t ...Indices_>
    void Get(Result_ &result, Hypothesis_ &hypothesis, std::index_sequence<Indices_...>) const {
        ((std::get<Offset_ + Indices_>(result) = uint256_t(std::get<Index_ + Indices_>(hypothesis).asString())), ...);
    }

    uint256_t Get(unsigned index, const Json::Value &storages, const Region &root, const uint256_t &key) const;

    template <size_t Offset_, size_t Index_, typename Result_, typename... Args_>
    void Get(Result_ &result, const Json::Value &storages, const Region &root) const {
    }

    template <size_t Offset_, size_t Index_, typename Result_, typename... Args_>
    void Get(Result_ &result, const Json::Value &storages, const Region &root, const uint256_t &key, Args_ &&...args) const {
        std::get<Offset_ + Index_>(result) = Get(Index_, storages, root, key);
        Get<Offset_, Index_ + 1>(result, storages, root, std::forward<Args_>(args)...);
    }

  public:
    Endpoint(S<Origin> origin, Locator locator, Flags flags = Flags()) :
        origin_(std::move(origin)),
        locator_(std::move(locator)),
        flags_(flags)
    {
    }

    task<Json::Value> operator ()(const std::string &method, Argument args) const;

    task<uint256_t> Chain() const;
    task<uint256_t> Bid() const;
    task<uint64_t> Height() const;

    task<Block> Header(const Argument &height) const;
    task<uint256_t> Balance(const Address &address) const;
    task<std::optional<Receipt>> operator [](const Bytes32 &transaction) const;

    task<Address> Resolve(const Argument &height, const std::string &name) const;

    template <typename... Args_>
    task<std::tuple<Account, typename Result_<Args_>::type...>> Get(const Block &block, const Address &contract, std::nullptr_t, Args_ &&...args) const {
        if (flags_.insecure_) {
            const auto hypothesis(*co_await Parallel(
                operator ()("eth_getTransactionCount", {contract, block.height_}),
                operator ()("eth_getBalance", {contract, block.height_}),
                operator ()("eth_getStorageAt", {contract, uint256_t(args), block.height_})...));
            std::tuple<Account, typename Result_<Args_>::type...> result(Account(uint256_t(std::get<0>(hypothesis).asString()), uint256_t(std::get<1>(hypothesis).asString())));
            Get<1, 2>(result, hypothesis, std::index_sequence_for<Args_...>());
            co_return result;
        } else {
            const auto proof(co_await operator ()("eth_getProof", {contract, {uint256_t(std::forward<Args_>(args))...}, block.height_}));
            std::tuple<Account, typename Result_<Args_>::type...> result(Account(block, proof));
            Number<uint256_t> root(proof["storageHash"].asString());
            Get<1, 0>(result, proof["storageProof"], root, std::forward<Args_>(args)...);
            co_return result;
        }
    }

    template <typename... Args_>
    task<std::tuple<typename Result_<Args_>::type...>> Get(const Block &block, const Address &contract, const uint256_t &storage, Args_ &&...args) const {
        if (flags_.insecure_) {
            const auto hypothesis(*co_await Parallel(
                operator ()("eth_getStorageAt", {contract, uint256_t(args), block.height_})...));
            std::tuple<typename Result_<Args_>::type...> result;
            Get<0, 0>(result, hypothesis, std::index_sequence_for<Args_...>());
            co_return result;
        } else {
            const auto proof(co_await operator ()("eth_getProof", {contract, {uint256_t(std::forward<Args_>(args))...}, block.height_}));
            std::tuple<typename Result_<Args_>::type...> result;
            Number<uint256_t> root(proof["storageHash"].asString());
            orc_assert(storage == root.num<uint256_t>());
            Get<0, 0>(result, proof["storageProof"], root, std::forward<Args_>(args)...);
            co_return result;
        }
    }

    task<std::tuple<Account, std::vector<uint256_t>>> Get(const Block &block, const Address &contract, const std::vector<uint256_t> &args) const {
        const auto proof(co_await operator ()("eth_getProof", {contract, args, block.height_}));
        std::tuple<Account, std::vector<uint256_t>> result(Account(block, proof));
        Number<uint256_t> root(proof["storageHash"].asString());
        auto storages(proof["storageProof"]);
        for (size_t i(0); i != args.size(); ++i)
            std::get<1>(result).emplace_back(Get(i, storages, root, args[i]));
        co_return result;
    }

    task<Bytes32> Send(const std::string &method, Argument args) const {
        co_return Bless((co_await operator ()(method, std::move(args))).asString());
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

    task<Result_> Call(const Endpoint &endpoint, const Argument &height, const Address &target, const uint256_t &gas, const Args_ &...args) const { orc_block({
        Builder builder;
        Coder<Args_...>::Encode(builder, std::forward<const Args_>(args)...);
        auto data(Bless((co_await endpoint("eth_call", {Multi{
            {"to", target},
            {"gas", gas},
            {"data", Tie(*this, builder)},
        }, height})).asString()));
        Window window(data);
        auto result(Coded<Result_>::Decode(window));
        window.Stop();
        co_return std::move(result);
    }, "calling " << Name()); }

    task<Result_> Call(const Endpoint &endpoint, const Address &from, const Argument &height, const Address &target, const uint256_t &gas, const Args_ &...args) const { orc_block({
        Builder builder;
        Coder<Args_...>::Encode(builder, std::forward<const Args_>(args)...);
        auto data(Bless((co_await endpoint("eth_call", {Multi{
            {"from", from},
            {"to", target},
            {"gas", gas},
            {"data", Tie(*this, builder)},
        }, height})).asString()));
        Window window(data);
        auto result(Coded<Result_>::Decode(window));
        window.Stop();
        co_return std::move(result);
    }, "calling " << Name()); }
};

template <typename... Args_>
class Contract final :
    public Region
{
  private:
    Beam data_;

  public:
    Contract(Beam data) :
        data_(std::move(data))
    {
    }

    const uint8_t *data() const override {
        return data_.data();
    }

    size_t size() const override {
        return data_.size();
    }

    Builder operator ()(const Args_ &...args) const {
        Builder builder;
        builder += *this;
        Coder<Args_...>::Encode(builder, std::forward<const Args_>(args)...);
        return builder;
    }
};

}

#endif//ORCHID_ENDPOINT_HPP
