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


#include <openssl/base.h>
#include <openssl/pkcs12.h>

#include "error.hpp"
#include "fit.hpp"
#include "integer.hpp"
#include "store.hpp"

namespace bssl {
    BORINGSSL_MAKE_DELETER(PKCS12, PKCS12_free)
    BORINGSSL_MAKE_STACK_DELETER(X509, X509_free)
}

namespace orc {

std::string Stringify(bssl::UniquePtr<BIO> bio) {
    char *data;
    // BIO_get_mem_data is an inline macro with a char * cast
    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-cstyle-cast)
    size_t size(BIO_get_mem_data(bio.get(), &data));
    return {data, size};
}

Store::Store(std::string key, std::string certificates) :
    key_(std::move(key)),
    certificates_(std::move(certificates))
{
}

Store::Store(const std::string &store) {
    bssl::UniquePtr<PKCS12> p12([&]() {
        bssl::UniquePtr<BIO> bio(BIO_new_mem_buf(store.data(), Fit(store.size())));
        orc_assert(bio);

        return d2i_PKCS12_bio(bio.get(), nullptr);
    }());

    orc_assert(p12);

    bssl::UniquePtr<EVP_PKEY> pkey;
    bssl::UniquePtr<X509> x509;
    bssl::UniquePtr<STACK_OF(X509)> stack;

    std::tie(pkey, x509, stack) = [&]() {
        EVP_PKEY *pkey(nullptr);
        X509 *x509(nullptr);
        STACK_OF(X509) *stack(nullptr);
        orc_assert(PKCS12_parse(p12.get(), "", &pkey, &x509, &stack));

        return std::tuple<
            bssl::UniquePtr<EVP_PKEY>,
            bssl::UniquePtr<X509>,
            bssl::UniquePtr<STACK_OF(X509)>
        >(pkey, x509, stack);
    }();

    orc_assert(pkey);
    orc_assert(x509);

    key_ = Stringify([&]() {
        bssl::UniquePtr<BIO> bio(BIO_new(BIO_s_mem()));
        orc_assert(PEM_write_bio_PrivateKey(bio.get(), pkey.get(), nullptr, nullptr, 0, nullptr, nullptr));
        return bio;
    }());

    certificates_ = Stringify([&]() {
        bssl::UniquePtr<BIO> bio(BIO_new(BIO_s_mem()));
        orc_assert(PEM_write_bio_X509(bio.get(), x509.get()));
        return bio;
    }());

    for (auto e(stack != nullptr ? sk_X509_num(stack.get()) : 0), i(decltype(e)(0)); i != e; i++)
        certificates_ += Stringify([&]() {
            bssl::UniquePtr<BIO> bio(BIO_new(BIO_s_mem()));
            orc_assert(PEM_write_bio_X509(bio.get(), sk_X509_value(stack.get(), i)));
            return bio;
        }());
}

}
