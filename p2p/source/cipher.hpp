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


#ifndef ORCHID_CIPHER_HPP
#define ORCHID_CIPHER_HPP

#include <openssl/evp.h>

#include "buffer.hpp"

namespace orc {

class Ctx {
  private:
    EVP_CIPHER_CTX *ctx_;

  public:
    Ctx();
    Ctx(const Ctx &&ctx) = delete;
    ~Ctx();

    operator EVP_CIPHER_CTX *() const {
        return ctx_;
    }

    operator size_t() const {
        return EVP_CIPHER_block_size(EVP_CIPHER_CTX_cipher(ctx_));
    }
};

class Encipher {
  private:
    Ctx ctx_;

  public:
    Encipher(const EVP_CIPHER *algorithm, const Region &key, const Region &iv = Beam());
    Beam operator ()(const Buffer &data) const;
    Beam operator ()() const;

    static Beam All(const EVP_CIPHER *algorithm, const Region &key, const Region &iv, const Buffer &data) {
        const Encipher cipher(algorithm, key, iv);
        const auto lhs(cipher(data));
        const auto rhs(cipher());
        return Beam(Tie(lhs, rhs));
    }
};

class Decipher {
  private:
    Ctx ctx_;

  public:
    Decipher(const EVP_CIPHER *algorithm, const Region &key, const Region &iv = Beam());
    Beam operator ()(const Buffer &data) const;
    Beam operator ()() const;

    static Beam All(const EVP_CIPHER *algorithm, const Region &key, const Region &iv, const Buffer &data) {
        const Decipher cipher(algorithm, key, iv);
        const auto lhs(cipher(data));
        const auto rhs(cipher());
        return Beam(Tie(lhs, rhs));
    }
};

}

#endif//ORCHID_CIPHER_HPP
