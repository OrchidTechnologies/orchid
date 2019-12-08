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


#ifndef ORCHID_CRYPTO_HPP
#define ORCHID_CRYPTO_HPP

#include "buffer.hpp"

#define _crycall(code) do { \
    orc_assert((code) == 0); \
} while (false)

namespace orc {

void Random(uint8_t *data, size_t size);

template <size_t Size_>
Brick<Size_> Random() {
    Brick<Size_> value;
    Random(value.data(), value.size());
    return value;
}

Brick<32> Hash(const Buffer &data);
Brick<32> Hash(const std::string &data);

struct Signature {
    Brick<32> r_;
    Brick<32> s_;
    uint8_t v_;

    Signature(const Brick<65> &data);
    Signature(const Brick<64> &data, int v);
    Signature(const Brick<32> &r, const Brick<32> &s, uint8_t v);

    operator Brick<65>() {
        auto [external] = Take<Brick<65>>(Tie(r_, s_, Number<uint8_t>(v_)));
        return external;
    }
};

using Secret = Brick<32>;
using Common = Brick<64>;
Common Commonize(const Secret &secret);

Signature Sign(const Secret &secret, const Brick<32> &data);
Common Recover(const Brick<32> &data, const Signature &signature);

inline Common Recover(const Brick<32> &data, uint8_t v, const Brick<32> &r, const Brick<32> &s) {
    return Recover(data, Signature(r, s, v));
}

Beam Object(int nid);
Beam Object(const char *ln);

size_t Length(Window &window);

}

#endif//ORCHID_CRYPTO_HPP
