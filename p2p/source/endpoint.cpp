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


#include "endpoint.hpp"
#include "error.hpp"
#include "http.hpp"
#include "json.hpp"

namespace orc {

static Explode Verify(Json::Value &proofs, Brick<32> hash, const Region &path) {
    size_t offset(0);
    orc_assert(!proofs.isNull());
    for (auto e(proofs.size()), i(decltype(e)(0)); i != e; ++i) {
        const auto data(Bless(proofs[i].asString()));
        orc_assert(Hash(data) == hash);

        Explode proof(data);
        switch (proof.size()) {
            case 17: {
                if (offset == path.size() * 2)
                    return Window(proof[16].buf());
                hash = proof[path.nib(offset++)].buf();
            } break;

            case 2: {
                const auto leg(proof[0].buf());
                const auto type(leg.nib(0));
                for (size_t i((type & 0x1) != 0 ? 1 : 2), e(leg.size() * 2); i != e; ++i)
                    orc_assert(path.nib(offset++) == leg.nib(i));
                const Range range(proof[1].buf());
                if ((type & 0x2) != 0)
                    return Window(range);
                hash = range;
            } break;

            default:
                orc_assert(false);
        }
    }

    orc_assert(false);
}

Block::Block(Json::Value &&value) :
    number_(value["number"].asString()),
    state_(value["stateRoot"].asString())
{
}

Account::Account(const Block &block, Json::Value &value) :
    nonce_(value["nonce"].asString()),
    balance_(value["balance"].asString()),
    storage_(value["storageHash"].asString()),
    code_(value["codeHash"].asString())
{
    auto leaf(Verify(value["accountProof"], Number<uint256_t>(block.state_), Hash(Number<uint160_t>(value["address"].asString()))));
    orc_assert(leaf.size() == 4);
    orc_assert(leaf[0].num() == nonce_);
    orc_assert(leaf[1].num() == balance_);
    orc_assert(leaf[2].num() == storage_);
    orc_assert(leaf[3].num() == code_);
}

uint256_t Endpoint::Get(int index, Json::Value &storages, const Region &root, const uint256_t &key) const {
    auto storage(storages[index]);
    orc_assert(uint256_t(storage["key"].asString()) == key);
    uint256_t value(storage["value"].asString());
    auto leaf(Verify(storage["proof"], root, Hash(Number<uint256_t>(key))));
    orc_assert(leaf.num() == value);
    return value;
}

task<Json::Value> Endpoint::operator ()(const std::string &method, Argument args) const {
    Json::Value root;
    root["jsonrpc"] = "2.0";
    root["method"] = method;
    root["id"] = "";
    root["params"] = std::move(args);

    Json::FastWriter writer;
    const auto data(Parse((co_await origin_->Request("POST", locator_, {{"content-type", "application/json"}}, writer.write(root))).ok()));
    Log() << root << " -> " << data << "" << std::endl;

    orc_assert(data["jsonrpc"] == "2.0");

    const auto error(data["error"]);

    const auto id(data["id"]);
    orc_assert(!id.isNull() || !error.isNull());

    orc_assert_(error.isNull(), ([&]() {
        auto text(writer.write(error));
        orc_assert(!text.empty());
        orc_assert(text[text.size() - 1] == '\n');
        text.resize(text.size() - 1);
        return text;
    }()));

    orc_assert(id == "");
    co_return data["result"];
}

}
