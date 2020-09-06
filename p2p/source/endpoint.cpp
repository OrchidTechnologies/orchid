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


#include <regex>

#include "endpoint.hpp"
#include "error.hpp"
#include "json.hpp"

namespace orc {

static Nested Verify(const Json::Value &proofs, Brick<32> hash, const Region &path) {
    size_t offset(0);
    orc_assert(!proofs.isNull());
    for (auto e(proofs.size()), i(decltype(e)(0)); i != e; ++i) {
        const auto data(Bless(proofs[i].asString()));
        orc_assert(Hash(data) == hash);

        const auto proof(Explode(data));
        switch (proof.size()) {
            case 17: {
                if (offset == path.size() * 2)
                    return Explode(proof[16].buf());
                const auto data(proof[path.nib(offset++)].buf());
                if (data.size() == 0)
                    return Nested();
                hash = data;
            } break;

            case 2: {
                const auto leg(proof[0].buf());
                const auto type(leg.nib(0));
                for (size_t i((type & 0x1) != 0 ? 1 : 2), e(leg.size() * 2); i != e; ++i)
                    if (path.nib(offset++) != leg.nib(i))
                        return Nested();
                const Segment segment(proof[1].buf());
                if ((type & 0x2) != 0)
                    return Explode(segment);
                hash = segment;
            } break;

            default:
                orc_assert(false);
        }
    }

    orc_assert(false);
}

Block::Block(Json::Value &&value) :
    number_(value["number"].asString()),
    state_(value["stateRoot"].asString()),
    timestamp_(value["timestamp"].asString())
{
}

Receipt::Receipt(Json::Value &&value) :
    contract_([&]() -> Address {
        const auto contract(value["contractAddress"]);
        if (contract.isNull())
            return Address();
        return contract.asString();
    }()),
    gas_(value["gasUsed"].asString())
{
}

Account::Account(const Block &block, const Json::Value &value) :
    nonce_(value["nonce"].asString()),
    balance_(value["balance"].asString()),
    storage_(value["storageHash"].asString()),
    code_(value["codeHash"].asString())
{
    const auto leaf(Verify(value["accountProof"], Number<uint256_t>(block.state_), Hash(Number<uint160_t>(value["address"].asString()))));
    orc_assert(leaf.size() == 4);
    orc_assert(leaf[0].num() == nonce_);
    orc_assert(leaf[1].num() == balance_);
    orc_assert(leaf[2].num() == storage_);
    orc_assert(leaf[3].num() == code_);
}

uint256_t Endpoint::Get(int index, const Json::Value &storages, const Region &root, const uint256_t &key) const {
    const auto storage(storages[index]);
    orc_assert(uint256_t(storage["key"].asString()) == key);
    const uint256_t value(storage["value"].asString());
    const auto leaf(Verify(storage["proof"], root, Hash(Number<uint256_t>(key))));
    orc_assert(leaf.num() == value);
    return value;
}

static Brick<32> Name(const std::string &name) {
    if (name.empty())
        return Zero<32>();
    const auto period(name.find('.'));
    if (period == std::string::npos)
        return Hash(Tie(Zero<32>(), Hash(name)));
    return Hash(Tie(Name(name.substr(period + 1)), Hash(name.substr(0, period))));
}

task<Json::Value> Endpoint::operator ()(const std::string &method, Argument args) const {
    Json::FastWriter writer;

    const auto body(writer.write([&]() {
        Json::Value root;
        root["jsonrpc"] = "2.0";
        root["method"] = method;
        root["id"] = "";
        root["params"] = std::move(args);
        return root;
    }()));

    const auto data(Parse((co_await origin_->Fetch("POST", locator_, {{"content-type", "application/json"}}, body)).ok()));
    if (Verbose)
        Log() << body << " -> " << data << "" << std::endl;
    orc_assert(data["jsonrpc"] == "2.0");

    const auto error(data["error"]);
    if (!error.isNull()) {
        auto text(writer.write(error));
        orc_assert(!text.empty());
        orc_assert(text[text.size() - 1] == '\n');
        text.resize(text.size() - 1);
        orc_throw(text);
    }

    const auto id(data["id"]);
    orc_assert(!id.isNull());
    orc_assert(id == "");
    co_return data["result"];
}

task<uint256_t> Endpoint::Latest() const {
    const auto number(uint256_t((co_await operator ()("eth_blockNumber", {})).asString()));
    orc_assert_(number != 0, "ethereum server has not synchronized any blocks");
    co_return number;
}

task<Block> Endpoint::Header(const Argument &number) const {
    co_return co_await operator ()("eth_getBlockByNumber", {number, false});
}

task<uint256_t> Endpoint::Balance(const Address &address) const {
    co_return uint256_t((co_await operator ()("eth_getBalance", {address, "latest"})).asString());
}

task<Receipt> Endpoint::Receipt(const Bytes32 &transaction) const {
    auto receipt(co_await operator ()("eth_getTransactionReceipt", {transaction}));
    orc_assert(!receipt.isNull());
    co_return std::move(receipt);
}

task<Brick<65>> Endpoint::Sign(const Address &signer, const Buffer &data) const {
    co_return Bless((co_await operator ()("eth_sign", {signer, data})).asString());
}

task<Brick<65>> Endpoint::Sign(const Address &signer, const std::string &password, const Buffer &data) const {
    co_return Bless((co_await operator ()("personal_sign", {signer, data, password})).asString());
}

task<Address> Endpoint::Resolve(const Argument &number, const std::string &name) const {
    static const std::regex re("0x[0-9A-Fa-f]{40}");
    if (std::regex_match(name, re))
        co_return name;

    const auto node(Name(name));
    static const Address ens("0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e");

    static const Selector<Address, Bytes32> resolver_("resolver");
    const auto resolver(co_await resolver_.Call(*this, number, ens, 90000, node));

    static const Selector<Address, Bytes32> addr_("addr");
    co_return co_await addr_.Call(*this, number, resolver, 90000, node);
}

}
