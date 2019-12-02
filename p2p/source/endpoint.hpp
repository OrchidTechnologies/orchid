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

    Block(Json::Value &&value);
};

struct Account final {
    const uint256_t nonce_;
    const uint256_t balance_;
    const uint256_t storage_;
    const uint256_t code_;

    Account(const Block &block, Json::Value &value);
};

template <typename Type_>
struct Result final {
    typedef uint256_t type;
};

class Endpoint final {
  private:
    const S<Origin> origin_;
    const Locator locator_;

    uint256_t Get(int index, Json::Value &storages, const Region &root, const uint256_t &key);

    template <int Index_, typename Result_, typename... Args_>
    void Get(Result_ &result, Json::Value &storages, const Region &root) {
    }

    template <int Index_, typename Result_, typename... Args_>
    void Get(Result_ &result, Json::Value &storages, const Region &root, const uint256_t &key, Args_ &&...args) {
        std::get<Index_ + 1>(result) = Get(Index_, storages, root, key);
        Get<Index_ + 1>(result, storages, root, std::forward<Args_>(args)...);
    }

  public:
    Endpoint(S<Origin> origin, Locator locator) :
        origin_(std::move(origin)),
        locator_(std::move(locator))
    {
    }

    task<Json::Value> operator ()(const std::string &method, Argument args);

    task<uint256_t> Latest() {
        auto latest(uint256_t((co_await operator ()("eth_blockNumber", {})).asString()));
        orc_assert_(latest != 0, "ethereum server has not synchronized any blocks");
        co_return latest;
    }

    task<Block> Header(uint256_t number) {
        co_return co_await operator ()("eth_getBlockByNumber", {number, false});
    }

    template <typename... Args_>
    task<std::tuple<Account, typename Result<Args_>::type...>> Get(const Block &block, const Address &contract, Args_ &&...args) {
        auto proof(co_await operator ()("eth_getProof", {contract, {std::forward<Args_>(args)...}, block.number_}));
        std::tuple<Account, typename Result<Args_>::type...> result(Account(block, proof));
        Number<uint256_t> root(proof["storageHash"].asString());
        Get<0>(result, proof["storageProof"], root, std::forward<Args_>(args)...);
        co_return result;
    }

    template <typename... Args_>
    task<std::tuple<Account, std::vector<uint256_t>>> Get(const Block &block, const Address &contract, const std::vector<uint256_t> &args) {
        auto proof(co_await operator ()("eth_getProof", {contract, {std::forward<Args_>(args)...}, block.number_}));
        std::tuple<Account, std::vector<uint256_t>> result(Account(block, proof));
        Number<uint256_t> root(proof["storageHash"].asString());
        auto storages(proof["storageProof"]);
        for (unsigned i(0); i != args.size(); ++i)
            std::get<1>(result).emplace_back(Get(i, storages, root, args[i]));
        co_return result;
    }

    task<Bytes32> Sign(const Address &signer, const Buffer &data) {
        co_return Bless((co_await operator ()("eth_sign", {signer, data})).asString());
    }
};

template <typename Result_, typename... Args_>
class Selector final :
    public Region
{
  private:
    uint32_t value_;
    uint256_t gas_;

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
    Selector(uint32_t value, uint256_t gas = 90000) :
        value_(boost::endian::native_to_big(value)),
        gas_(std::move(gas))
    {
    }

    // XXX: the r20 clang-tidy doesn't seem to do this correctly
    // NOLINTNEXTLINE (performance-unnecessary-value-param)
    Selector(const std::string &name, uint256_t gas = 90000) :
        Selector([&]() {
            std::ostringstream signature;
            signature << name << '(';
            Args<false, Args_...>::Write(signature);
            signature << ')';
            std::cerr << signature.str() << std::endl;
            return Hash(Strung(signature.str())).Clip<4>().num<uint32_t>();
        }(), std::move(gas))
    {
    }

    const uint8_t *data() const override {
        return reinterpret_cast<const uint8_t *>(&value_);
    }

    size_t size() const override {
        return sizeof(value_);
    }

    task<Result_> Call(Endpoint &endpoint, const Argument &block, const Address &contract, const Args_ &...args) {
        Builder builder;
        Coder<Args_...>::Encode(builder, std::forward<const Args_>(args)...);
        auto data(Bless((co_await endpoint("eth_call", {Map{
            {"to", contract},
            {"gas", gas_},
            {"data", Tie(*this, builder)},
        }, block})).asString()));
        Window window(data);
        auto result(Coded<Result_>::Decode(window));
        window.Stop();
        co_return std::move(result);
    }

    task<Result_> Call(Endpoint &endpoint, const Address &from, const Argument &block, const Address &contract, const Args_ &...args) {
        Builder builder;
        Coder<Args_...>::Encode(builder, std::forward<const Args_>(args)...);
        auto data(Bless((co_await endpoint("eth_call", {Map{
            {"from", from},
            {"to", contract},
            {"gas", gas_},
            {"data", Tie(*this, builder)},
        }, block})).asString()));
        Window window(data);
        auto result(Coded<Result_>::Decode(window));
        window.Stop();
        co_return std::move(result);
    }

    task<uint256_t> Send(Endpoint &endpoint, const Address &from, const Address &contract, const Args_ &...args) {
        Builder builder;
        Coder<Args_...>::Encode(builder, std::forward<const Args_>(args)...);
        auto transaction(Bless((co_await endpoint("eth_sendTransaction", {Map{
            {"from", from},
            {"to", contract},
            {"gas", gas_},
            {"data", Tie(*this, builder)},
        }})).asString()).template num<uint256_t>());
        co_return std::move(transaction);
    }

    task<uint256_t> Send(Endpoint &endpoint, const Address &from, const std::string &password, const Address &contract, const Args_ &...args) {
        Builder builder;
        Coder<Args_...>::Encode(builder, std::forward<const Args_>(args)...);
        auto transaction(Bless((co_await endpoint("personal_sendTransaction", {Map{
            {"from", from},
            {"to", contract},
            {"gas", gas_},
            {"data", Tie(*this, builder)},
        }, password})).asString()).template num<uint256_t>());
        co_return std::move(transaction);
    }
};

}

#endif//ORCHID_ENDPOINT_HPP
