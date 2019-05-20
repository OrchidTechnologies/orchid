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


#include <boost/random.hpp>
#include <boost/random/random_device.hpp>

#include <ethash/keccak.hpp>

#include "crypto.hpp"
#include "trace.hpp"

namespace orc {

void Random(uint8_t *data, size_t size) {
    static auto generator([]() {
        boost::random::independent_bits_engine<boost::mt19937, 128, uint128_t> generator;
        generator.seed(boost::random::random_device()());
        return generator;
    }());
    generator.generate(data, data + size);
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
