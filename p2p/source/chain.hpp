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


#ifndef ORCHID_CHAIN_HPP
#define ORCHID_CHAIN_HPP

#include "base.hpp"
#include "crypto.hpp"
#include "endpoint.hpp"
#include "fit.hpp"
#include "jsonrpc.hpp"
#include "locator.hpp"
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
    // XXX: type_ probably shouldn't be stored
    const uint8_t type_;
    const uint256_t nonce_;
    const uint256_t bid_;
    const uint64_t gas_;
    const std::optional<Address> target_;
    const uint256_t amount_;
    const Beam data_;
    const std::vector<std::pair<Address, std::vector<Bytes32>>> access_;

    Bytes32 hash(const uint256_t &chain, const uint256_t &v, const uint256_t &r, const uint256_t &s) const;
    Address from(const uint256_t &chain, const uint256_t &v, const uint256_t &r, const uint256_t &s) const;
};

struct Record final :
    public Transaction
{
    const Bytes32 hash_;
    const Address from_;

    Record(
        const uint256_t &nonce,
        const uint256_t &bid,
        const uint64_t &gas,
        const std::optional<Address> &target,
        const uint256_t &amount,
        Beam data,

        const uint256_t &chain,
        const uint256_t &v,
        const uint256_t &r,
        const uint256_t &s
    );

    Record(const uint256_t &chain, const Json::Value &value);
};

struct Block {
    const uint64_t height_;
    const Brick<32> state_;
    const uint64_t timestamp_;
    const uint64_t limit_;
    const Address miner_;
    const std::vector<Record> records_;

    Block(const uint256_t &chain, Json::Value &&value);
};

struct Account final {
    const uint256_t nonce_;
    const uint256_t balance_;
    const Brick<32> storage_;
    const Brick<32> code_;

    Account(const uint256_t &nonce, const uint256_t &balance);
    Account(const Block &block, const Json::Value &value);
};

struct Flags {
    bool verbose_ = false;
    std::optional<uint256_t> bid_;
};

class Chain :
    public Valve,
    public Endpoint
{
  private:
    template <typename Type_>
    struct Result_ final {
        typedef uint256_t type;
    };

    const Flags flags_;
    const uint256_t chain_;

    bool Insecure() const {
        // RSK {"jsonrpc":"2.0","id":0,"error":{"code":-32601,"message":"method not found"}}
        if (chain_ == 30)
            return true;

        // Ganache "Implement eth_getProof RPC message" https://github.com/trufflesuite/ganache-core/issues/382
        if (chain_ == 1337)
            return true;

        return false;
    }

    template <size_t Offset_, int Index_, typename Result_, typename Hypothesis_, size_t ...Indices_>
    void Get(Result_ &result, Hypothesis_ &hypothesis, std::index_sequence<Indices_...>) const {
        ((std::get<Offset_ + Indices_>(result) = uint256_t(std::get<Index_ + Indices_>(hypothesis).asString())), ...);
    }

    uint256_t Get(Json::Value::ArrayIndex index, const Json::Value &storages, const Region &root, const uint256_t &key) const;

    template <size_t Offset_, size_t Index_, typename Result_, typename... Args_>
    void Get(Result_ &result, const Json::Value &storages, const Region &root) const {
    }

    template <size_t Offset_, size_t Index_, typename Result_, typename... Args_>
    void Get(Result_ &result, const Json::Value &storages, const Region &root, const uint256_t &key, Args_ &&...args) const {
        std::get<Offset_ + Index_>(result) = Get(Index_, storages, root, key);
        Get<Offset_, Index_ + 1>(result, storages, root, std::forward<Args_>(args)...);
    }

  public:
    Chain(Endpoint endpoint, Flags flags, uint256_t chain) :
        Valve(typeid(*this).name()),
        Endpoint(std::move(endpoint)),
        flags_(std::move(flags)),
        chain_(std::move(chain))
    {
    }

    Chain(const Chain &rhs) = delete;
    Chain(Chain &&rhs) = delete;

    static task<S<Chain>> New(Endpoint endpoint, Flags flags, uint256_t chain);
    static task<S<Chain>> New(Endpoint endpoint, Flags flags);

    task<void> Shut() noexcept override {
        co_await Valve::Shut();
    }

    operator const uint256_t &() const {
        return chain_;
    }

    bool operator ==(unsigned chain) const {
        return chain_ == chain;
    }

    task<uint256_t> Bid() const;
    task<uint64_t> Height() const;

    task<Block> Header(const Argument &height) const;
    task<std::optional<Receipt>> operator [](const Bytes32 &transaction) const;

    task<Address> Resolve(const Argument &height, const std::string &name) const;

    task<Beam> Code(const Block &block, const Address &contract) const {
        // XXX: verify hash
        auto code(Bless((co_await operator ()("eth_getCode", {contract, block.height_})).asString()));
        co_return std::move(code);
    }

    task<Account> Get(const Block &block, const Address &contract) const {
        co_return std::get<0>(co_await Get(block, contract, nullptr));
    }

    // XXX: xDAI incorrectly requires eth_getProof storage slot indices be DATA (Number), instead of QUANTITY (uint256_t)
    //      usually, you get back the following error message, but sometimes it just returns a proof of the wrong slot :/
    // {"code":-32602,"message":"Invalid params: invalid length 1, expected a 0x-prefixed hex string with length of 64."}

    template <typename... Args_>
    task<std::tuple<Account, typename Result_<Args_>::type...>> Get(const Block &block, const Address &contract, std::nullptr_t, Args_ &&...args) const {
        if (Insecure()) {
            const auto hypothesis(*co_await Parallel(
                operator ()("eth_getTransactionCount", {contract, block.height_}),
                operator ()("eth_getBalance", {contract, block.height_}),
                operator ()("eth_getStorageAt", {contract, uint256_t(args), block.height_})...));
            std::tuple<Account, typename Result_<Args_>::type...> result(Account(
                uint256_t(std::get<0>(hypothesis).asString()),
                uint256_t(std::get<1>(hypothesis).asString())));
            Get<1, 2>(result, hypothesis, std::index_sequence_for<Args_...>());
            co_return result;
        } else {
            const auto proof(co_await operator ()("eth_getProof", {contract, {Number<uint256_t>(std::forward<Args_>(args))...}, block.height_}));
            std::tuple<Account, typename Result_<Args_>::type...> result(Account(block, proof));
            Number<uint256_t> root(proof["storageHash"].asString());
            Get<1, 0>(result, proof["storageProof"], root, std::forward<Args_>(args)...);
            co_return result;
        }
    }

    template <typename... Args_>
    task<std::tuple<typename Result_<Args_>::type...>> Get(const Block &block, const Address &contract, const Brick<32> &storage, Args_ &&...args) const {
        if (Insecure()) {
            const auto hypothesis(*co_await Parallel(
                operator ()("eth_getStorageAt", {contract, uint256_t(args), block.height_})...));
            std::tuple<typename Result_<Args_>::type...> result;
            Get<0, 0>(result, hypothesis, std::index_sequence_for<Args_...>());
            co_return result;
        } else {
            const auto proof(co_await operator ()("eth_getProof", {contract, {Number<uint256_t>(std::forward<Args_>(args))...}, block.height_}));
            std::tuple<typename Result_<Args_>::type...> result;
            orc_assert(Number<uint256_t>(proof["storageHash"].asString()) == storage);
            Get<0, 0>(result, proof["storageProof"], storage, std::forward<Args_>(args)...);
            co_return result;
        }
    }

    task<std::tuple<Account, std::vector<uint256_t>>> Get(const Block &block, const Address &contract, const std::vector<uint256_t> &args) const {
        if (Insecure()) {
            orc_insist(false);
        } else {
            std::vector<Number<uint256_t>> numbers;
            for (const auto &arg : args)
                numbers.emplace_back(arg);
            const auto proof(co_await operator ()("eth_getProof", {contract, numbers, block.height_}));
            std::tuple<Account, std::vector<uint256_t>> result(Account(block, proof));
            Number<uint256_t> root(proof["storageHash"].asString());
            auto storages(proof["storageProof"]);
            for (Json::Value::ArrayIndex e(Fit(args.size())), i(0); i != e; ++i)
                std::get<1>(result).emplace_back(Get(i, storages, root, args[i]));
            co_return result;
        }
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


    static std::string Print() {
        return "()";
    }

    template <typename Next_, typename... Rest_>
    static std::string Print(const Next_ &next, const Rest_ &...rest) {
        std::ostringstream data;
        data << '(';
        data << next;
        ((data << ", " << rest), ...);
        data << ')';
        return std::move(data).str();
    }


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
        value_(boost::endian::native_to_big(HashK(name_).template Clip<0, 4>().template num<uint32_t>()))
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

    task<Result_> Call(const Chain &chain, const Argument &height, const Address &target, const uint256_t &gas, const Args_ &...args) const { orc_block({
        Builder builder;
        Coder<Args_...>::Encode(builder, std::forward<const Args_>(args)...);
        auto data(Bless((co_await chain("eth_call", {Multi{
            {"to", target},
            {"gas", gas},
            {"data", Tie(*this, builder)},
        }, height})).asString()));
        orc_block({
            Window window(data);
            auto result(Coded<Result_>::Decode(window));
            window.Stop();
            co_return std::move(result);
        }, "decoding " << data);
    }, "calling " << Name() << " with " << Print(args...)); }

    task<Result_> Call(const Chain &chain, const Address &from, const Argument &height, const Address &target, const uint256_t &gas, const Args_ &...args) const { orc_block({
        Builder builder;
        Coder<Args_...>::Encode(builder, std::forward<const Args_>(args)...);
        auto data(Bless((co_await chain("eth_call", {Multi{
            {"from", from},
            {"to", target},
            {"gas", gas},
            {"data", Tie(*this, builder)},
        }, height})).asString()));
        orc_block({
            Window window(data);
            auto result(Coded<Result_>::Decode(window));
            window.Stop();
            co_return std::move(result);
        }, "decoding " << data);
    }, "calling " << Name() << " with " << Print(args...)); }
};

template <typename... Args_>
class Constructor final :
    public Region
{
  private:
    Beam data_;

  public:
    Constructor(Beam data) :
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

#endif//ORCHID_CHAIN_HPP
