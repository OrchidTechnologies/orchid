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


#include "ethereum.hpp"

uint8_t nib(const uint8_t *data, size_t index) {
    const auto value(data[index >> 1]);
    return (index & 0x1) == 0 ? value >> 4 : value & 0xf;
}

cyk::Digest32 digest_;

template <size_t Size_, typename Code_>
void check(Code_ code) {
    cyk::Digest<Size_> data;
    cyk::read0(&data);

    // XXX: left-pad data to 256-bit?
    cyk::commit(data.data(), data.size());

    cyk::Digest32 path(cyk::keccak256(data.data(), data.size()));
    size_t offset(0);

    for (;;) {
        cyk_read0lve(data);
        cyk_assert(cyk::keccak256(data, sizeof(data)) == digest_);
        eth::Nested node(data, sizeof(data));

        switch (const auto size = node.next()) {
            case 0: case 32: {
                node.bump(-1);
                cyk_assert(offset < path.size() * 2);
                node.skip(nib(path.data(), offset++));
                node.read(&digest_);
            } break;

            default: {
                const auto leg(node.data());
                const auto type(nib(leg, 0));
                for (size_t i((type & 0x1) != 0 ? 1 : 2), e(size * 2); i != e; ++i)
                    cyk_assert(nib(path.data(), offset++) == nib(leg, i));
                node.bump(size);

                if ((type & 0x2) == 0) {
                    cyk_assert(offset != path.size() * 2);
                    node.read(&digest_);
                } else {
                    const size_t rest(node.next());
                    cyk_assert(rest == node.size());

                    cyk_assert(offset == path.size() * 2);
                    return code(node);
                }
            } break;
        }
    }
}

int main() {
    cyk_read0lve(data);
    cyk::commit(cyk::keccak256(data, sizeof(data)));

    eth::Nested block(data, sizeof(data));
    block.skip(3);
    block.read(&digest_);

    check<20>([&](eth::Nested &leaf) {
        eth::Nested account(leaf.data(), leaf.size());
        account.skip(2);
        account.read(&digest_);
    });

    check<32>([&](eth::Nested &leaf) {
        size_t size(leaf.next());
        cyk_assert(size <= digest_.size());
        digest_.clear();
        memcpy(digest_.data_ + digest_.size() - size, leaf.data(), size);
    });

    cyk::commit(digest_);
    return 0;
}
