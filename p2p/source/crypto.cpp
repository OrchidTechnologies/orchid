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


#include <ethash/keccak.hpp>

#include "crypto.hpp"
#include "trace.hpp"

namespace orc {

__attribute__((__constructor__))
static void SetupRandom() {
    orc_assert(sodium_init() != -1);
}

Brick<32> Hash(const Buffer &data) {
    Beam beam(data);
    auto hash(ethash_keccak256(beam.data(), beam.size()));
    Brick<sizeof(hash)> value;
    // the ethash_keccak56 API fundamentally requires a union
    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-union-access)
    memcpy(value.data(), hash.bytes, sizeof(hash));
    return value;
}

Brick<32> Hash(const std::string &data) {
    return Hash(Subset(data));
}

}
