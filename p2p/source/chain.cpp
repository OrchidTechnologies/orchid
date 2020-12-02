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


#include <regex>

#include "chain.hpp"
#include "error.hpp"
#include "json.hpp"
#include "nested.hpp"

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

Receipt::Receipt(Json::Value &&value) :
    height_(To(value["blockNumber"].asString())),
    status_([&]() {
        const uint256_t status(value["status"].asString());
        return status != 0;
    }()),
    contract_([&]() -> Address {
        const auto contract(value["contractAddress"]);
        if (contract.isNull())
            return Address();
        return contract.asString();
    }()),
    gas_(To(value["gasUsed"].asString()))
{
}

Bytes32 Transaction::hash(const uint256_t &v, const uint256_t &r, const uint256_t &s) const {
    return Hash(Implode({nonce_, bid_, gas_, target_, amount_, data_, v, r, s}));
}

Address Transaction::from(const uint256_t &chain, const uint256_t &v, const uint256_t &r, const uint256_t &s) const {
    if (v >= 35) {
        Signature signature(Number<uint256_t>(r), Number<uint256_t>(s), uint8_t(v - 35 - chain * 2));
        return Recover(Hash(Implode({nonce_, bid_, gas_, target_, amount_, data_, chain, uint8_t(0), uint8_t(0)})), signature);
    } else {
        orc_assert(v >= 27);
        Signature signature(Number<uint256_t>(r), Number<uint256_t>(s), uint8_t(v - 27));
        return Recover(Hash(Implode({nonce_, bid_, gas_, target_, amount_, data_})), signature);
    }
}

Record::Record(
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
) :
    Transaction{nonce, bid, gas, target, amount, std::move(data)},

    hash_(hash(v, r, s)),
    from_(from(chain, v, r, s))
{
}

Record::Record(const uint256_t &chain, const Json::Value &value) :
    Transaction{
        uint256_t(value["nonce"].asString()),
        uint256_t(value["gasPrice"].asString()),
        To(value["gas"].asString()),
        [&]() -> std::optional<Address> {
            const auto &target(value["to"]);
            if (target.isNull())
                return std::nullopt;
            return target.asString();
        }(),
        uint256_t(value["value"].asString()),
        Bless(value["input"].asString())
    },

    hash_(Bless(value["hash"].asString())),
    from_(value["from"].asString())
{
    // XXX: RSK incorrectly returns the v value from EIP155 encodings
    // https://github.com/rsksmart/rskj/issues/1380
    // XXX: RSK might have further broken stuff? more research needed
    // https://github.com/rsksmart/RSKIPs/blob/master/IPs/RSKIP138.md
    if (chain == 30)
        return;

    const uint256_t v(value["v"].asString());
    const uint256_t r(value["r"].asString());
    const uint256_t s(value["s"].asString());

    orc_assert(hash_ == hash(v, r, s));
    orc_assert(from_ == from(chain, v, r, s));
}

Block::Block(const uint256_t &chain, Json::Value &&value) :
    height_(To(value["number"].asString())),
    state_(value["stateRoot"].asString()),
    timestamp_(To(value["timestamp"].asString())),
    limit_(To(value["gasLimit"].asString())),
    miner_(value["miner"].asString()),

    records_([&]() {
        std::vector<Record> records;
        for (auto &record : value["transactions"])
            records.emplace_back(chain, std::move(record));
        return records;
    }())
{
    // XXX: verify transaction root
}

Account::Account(const uint256_t &nonce, const uint256_t &balance) :
    nonce_(nonce),
    balance_(balance)
{
}

Account::Account(const Block &block, const Json::Value &value) :
    nonce_(value["nonce"].asString()),
    balance_(value["balance"].asString()),
    storage_(value["storageHash"].asString()),
    code_(value["codeHash"].asString())
{
    const auto leaf(Verify(value["accountProof"], Number<uint256_t>(block.state_), Hash(Number<uint160_t>(value["address"].asString()))));
    if (leaf.scalar()) {
        orc_assert(leaf.buf().size() == 0);
        orc_assert(nonce_ == 0);
        orc_assert(balance_ == 0);
        orc_assert(storage_ == uint256_t("0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421"));
        orc_assert(code_ == uint256_t("0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"));
    } else {
        orc_assert(leaf.size() == 4);
        orc_assert(leaf[0].num() == nonce_);
        orc_assert(leaf[1].num() == balance_);
        orc_assert(leaf[2].num() == storage_);
        orc_assert(leaf[3].num() == code_);
    }
}

uint256_t Chain::Get(unsigned index, const Json::Value &storages, const Region &root, const uint256_t &key) const {
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

task<S<Chain>> Chain::New(Endpoint endpoint, Flags flags, uint256_t chain) {
    co_return Break<Chain>(std::move(endpoint), std::move(flags), std::move(chain));
}

task<S<Chain>> Chain::New(Endpoint endpoint, Flags flags) {
    auto chain(
        endpoint.operator const Locator &().host_ == "cloudflare-eth.com" ? 1 :
        endpoint.operator const Locator &().host_ == "rpc.mainnet.near.org" ? 1313161554 :
    uint256_t((co_await endpoint("eth_chainId", {})).asString()));
    co_return co_await New(std::move(endpoint), std::move(flags), std::move(chain));
}

task<uint256_t> Chain::Bid() const {
    co_return flags_.bid_ ? *flags_.bid_ : uint256_t((co_await operator()("eth_gasPrice", {})).asString());
}

task<uint64_t> Chain::Height() const {
    const auto height(To((co_await operator ()("eth_blockNumber", {})).asString()));
    orc_assert_(height != 0, "ethereum server has not synchronized any blocks");
    co_return height;
}

task<Block> Chain::Header(const Argument &height) const {
    auto block(co_await operator ()("eth_getBlockByNumber", {height, true}));
    orc_assert(!block.isNull());
    co_return Block(chain_, std::move(block));
}

task<std::optional<Receipt>> Chain::operator [](const Bytes32 &transaction) const {
    auto receipt(co_await operator ()("eth_getTransactionReceipt", {transaction}));
    if (receipt.isNull())
        co_return std::optional<Receipt>();
    co_return std::optional<Receipt>(std::in_place, std::move(receipt));
}

task<Address> Chain::Resolve(const Argument &height, const std::string &name) const {
    static const std::regex re("0x[0-9A-Fa-f]{40}");
    if (std::regex_match(name, re))
        co_return name;

    const auto node(Name(name));
    static const Address ens("0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e");

    static const Selector<Address, Bytes32> resolver_("resolver");
    const auto resolver(co_await resolver_.Call(*this, height, ens, 90000, node));

    static const Selector<Address, Bytes32> addr_("addr");
    co_return co_await addr_.Call(*this, height, resolver, 90000, node);
}

}
