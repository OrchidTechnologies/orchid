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


#include "crypto.hpp"
#include "trace.hpp"

namespace orc {

__attribute__((__constructor__))
static void SetupRandom() {
    _assert(sodium_init() != -1);
}

Block<crypto_generichash_BYTES> Hash(const Buffer &data) {
    Block<crypto_generichash_BYTES> hash;
    crypto_generichash_state state;
    crypto_generichash_init(&state, NULL, 0, crypto_generichash_BYTES);
    data.each([&](const Region &region) {
        crypto_generichash_update(&state, region.data(), region.size());
        return true;
    });
    crypto_generichash_final(&state, hash.data(), hash.size());
    return hash;
}

}
