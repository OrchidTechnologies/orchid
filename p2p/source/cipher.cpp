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


#include "cipher.hpp"
#include "fit.hpp"
#include "scope.hpp"

namespace orc {

Ctx::Ctx() :
    ctx_(EVP_CIPHER_CTX_new())
{
    orc_assert(ctx_ != nullptr);
}

Ctx::~Ctx() {
    EVP_CIPHER_CTX_free(ctx_);
}

Encipher::Encipher(const EVP_CIPHER *algorithm, const Region &key, const Region &iv) {
    orc_assert(key.size() == EVP_CIPHER_key_length(algorithm));
    orc_assert(iv.size() == EVP_CIPHER_iv_length(algorithm));
    orc_assert(EVP_EncryptInit_ex(ctx_, algorithm, nullptr, key.data(), iv.data()) != 0);
}

Beam Encipher::operator ()(const Buffer &data) const {
    Beam output(data.size() + ctx_);
    size_t offset(0);

    data.each([&](const uint8_t *data, size_t size) {
        int writ;
        orc_assert(EVP_EncryptUpdate(ctx_, output.data() + offset, &writ, data, Fit(size)) != 0);
        offset += writ;
        return true;
    });

    output.size(offset);
    return output;
}

Beam Encipher::operator ()() const {
    Beam output(ctx_);
    int writ;
    orc_assert(EVP_EncryptFinal_ex(ctx_, output.data(), &writ) != 0);
    output.size(writ);
    return output;
}

Decipher::Decipher(const EVP_CIPHER *algorithm, const Region &key, const Region &iv) {
    orc_assert(key.size() == EVP_CIPHER_key_length(algorithm));
    orc_assert(iv.size() == EVP_CIPHER_iv_length(algorithm));
    orc_assert(EVP_DecryptInit_ex(ctx_, algorithm, nullptr, key.data(), iv.data()) != 0);
}

Beam Decipher::operator ()(const Buffer &data) const {
    Beam output(data.size() + ctx_);
    size_t offset(0);

    data.each([&](const uint8_t *data, size_t size) {
        int writ;
        orc_assert(EVP_DecryptUpdate(ctx_, output.data() + offset, &writ, data, Fit(size)) != 0);
        offset += writ;
        return true;
    });

    output.size(offset);
    return output;
}

Beam Decipher::operator ()() const {
    Beam output(ctx_);
    int writ;
    orc_assert(EVP_DecryptFinal_ex(ctx_, output.data(), &writ) != 0);
    output.size(writ);
    return output;
}

}
