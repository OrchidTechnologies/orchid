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


#include "chain.hpp"
#include "local.hpp"
#include "nested.hpp"

namespace orc {

typedef std::string Nibbles;

bool Similar(const Address &address, const Nibbles &nibbles) {
    const auto hash(HashK(Number<uint160_t>(address.num())));
    for (size_t i(0); i != nibbles.size(); ++i)
        if (hash.nib(i) != Bless(nibbles[i]))
            return false;
    return true;
}

template <size_t Size_, typename Code_, typename Each_>
task<void> Scan(const Brick<32> &root, Code_ &&code, Each_ &&each) {
    std::set<Nibbles> todo;
    todo.emplace(Nibbles());

    std::set<Nibbles> done;

    while (!todo.empty()) {
        const auto next(*todo.begin());

      next:
        const auto preimage(Random<Size_>());
        const auto hash(HashK(preimage).hex(false));
        if (hash.substr(0, next.size()) != next)
            goto next;

        size_t offset(0);

        auto check(root);

        const auto proofs(co_await code(preimage));
        for (size_t i(0); i != proofs.size(); ++i) {
            const auto here(hash.substr(0, offset));
            done.emplace(here);
            todo.erase(here);

            const auto data(Bless(Str(proofs[i])));
            orc_assert(HashK(data) == check);

            const auto proof(Explode(data));
            switch (proof.size()) {
                case 2: {
                    const auto leg(proof[0].buf());
                    const auto type(leg.nib(0));

                    const auto there(here + leg.hex(false).substr(2 - (type & 0x1)));
                    if ((type & 0x2) == 0) {
                        check = hash.substr(there.size()) != there ? EmptyVector : Brick<32>(proof[1].buf());
                        offset = there.size();
                        if (!done.contains(there))
                            todo.emplace(there);
                    } else {
                        check = EmptyVector;
                        orc_assert_(there.size() == 64, there.size() << " != 64");
                        each(Bless(there), Explode(proof[1].buf()));
                    }
                } break;

                case 17: {
                    const auto &scalar(proof[Bless(hash[offset++])]);
                    check = scalar.zero() ? EmptyVector : Brick<32>(scalar.buf());

                    orc_assert(proof[16].buf().done());
                    for (uint8_t i(0); i != 16; ++i) {
                        if (proof[i].buf().done())
                            continue;
                        const auto there(here + Hex(i));
                        if (!done.contains(there))
                            todo.emplace(there);
                    }
                } break;

                default: {
                    orc_assert_(false, proof.size());
                } break;
            }
        }

        todo.erase(Nibbles());
        orc_assert_(check == EmptyVector, check);
    }
}

task<void> ScanState(const S<Chain> &chain, uint64_t height) {
    const auto header(co_await chain->Header(height));

    co_await Scan<20>(header.state_, [&](const Brick<20> &account) -> task<Array> {
        co_return (co_await chain->Call("eth_getProof", {account, {}, height})).as_object().at("accountProof").as_array();
    }, [&](const Brick<32> &key, const Nested &data) {
        std::cout << key << " " << data << std::endl;
    });
}

task<void> ScanStorage(const S<Chain> &chain, uint64_t height, const Address &address) {
    const auto header(co_await chain->Header(height));

    const auto storage(Bless(Str((co_await chain->Call("eth_getProof", {address, {}, height})).as_object().at("storageHash"))));

    co_await Scan<32>(storage, [&](const Brick<32> &slot) -> task<Array> {
        co_return (co_await chain->Call("eth_getProof", {address, {slot}, height})).as_object().at("storageProof").as_array().at(0).as_object().at("proof").as_array();
    }, [&](const Brick<32> &key, const Nested &data) {
        std::cout << key << " = " << Number<uint256_t>(data.num()).hex(true) << std::endl;
    });
}

}
