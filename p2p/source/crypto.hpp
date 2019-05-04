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

#include <sodium.h>

#include "buffer.hpp"

#define _crycall(code) do { \
    orc_assert((code) == 0); \
} while (false)

namespace orc {

inline void Random(void *data, size_t size) {
    randombytes_buf(data, size);
}

template <size_t Size_>
Block<Size_> Random() {
    Block<Size_> value;
    Random(value.data(), value.size());
    return value;
}

Block<crypto_generichash_BYTES> Hash(const Buffer &data);

typedef Block<crypto_box_SECRETKEYBYTES> Secret;
typedef Block<crypto_box_PUBLICKEYBYTES> Common;

class Identity {
  private:
    Secret secret_;
    Common common_;

  public:
    Identity() {
        _crycall(crypto_box_keypair(common_.data(), secret_.data()));
    }

    Identity(const Secret &secret, const Common &common) :
        secret_(secret),
        common_(common)
    {
    }

    const Secret &GetSecret() {
        return secret_;
    }

    const Common &GetCommon() {
        return common_;
    }
};

typedef Block<crypto_box_BEFORENMBYTES> Shared;

static const size_t NonceSize = crypto_box_NONCEBYTES;

class Boxer final {
  private:
    Shared shared_;

  public:
    Boxer(const Secret &secret, const Common &target) {
        _crycall(crypto_box_beforenm(shared_.data(), target.data(), secret.data()));
    }

    Beam Close(const Buffer &buffer) {
        Beam beam(buffer);
        Beam value(beam.size() + NonceSize + crypto_box_MACBYTES);
        Random(value.data(), NonceSize);
        _crycall(crypto_box_easy_afternm(value.data() + NonceSize, beam.data(), beam.size(), value.data(), shared_.data()));
        return value;
    }

    Beam Open(const Buffer &buffer) {
        Beam beam(buffer);
        Beam value(beam.size() - NonceSize - crypto_box_MACBYTES);
        _crycall(crypto_box_open_easy_afternm(value.data(), beam.data() + NonceSize, beam.size() - NonceSize, beam.data(), shared_.data()));
        return value;
    }
};

}

#endif//ORCHID_CRYPTO_HPP
