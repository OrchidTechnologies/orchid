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

#include "secp256k1_preallocated.h"

int main() {
    cyk::Digest32 secret;
    cyk::read0(&secret);
    cyk::commit(secret);

    const auto flags(SECP256K1_CONTEXT_NONE);
    uint8_t buffer alignas(4) [secp256k1_context_preallocated_size(flags)];
    const auto context(secp256k1_context_preallocated_create(buffer, flags));

    secp256k1_pubkey key;
    cyk_assert(secp256k1_ec_pubkey_create(context, &key, secret.data()) != 0);

    uint8_t data[65];
    size_t size(sizeof(data));
    cyk_assert(secp256k1_ec_pubkey_serialize(context, data, &size, &key, SECP256K1_EC_UNCOMPRESSED) != 0);
    cyk_assert(size == sizeof(data));

    secp256k1_context_preallocated_destroy(context);

    const auto address(cyk::keccak256(data+1, 64));
    cyk::commit(address.data()+12, 20);
    return 0;
}
