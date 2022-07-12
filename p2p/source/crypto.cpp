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


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wimplicit-int-conversion"
#include <boost/random.hpp>
#include <boost/random/random_device.hpp>
#pragma clang diagnostic pop

#include <openssl/md5.h>
#include <openssl/objects.h>
#include <openssl/ripemd.h>
#include <openssl/sha.h>

#include <secp256k1_ecdh.h>
#include <secp256k1_recovery.h>

#include "crypto.hpp"
#include "fit.hpp"
#include "scope.hpp"

namespace orc {

void Random(uint8_t *data, size_t size) {
    static auto generator([]() {
        boost::random::independent_bits_engine<boost::mt19937, 128, uint128_t> generator;
        generator.seed(boost::random::random_device()());
        return generator;
    }());
    generator.generate(data, data + size);
}

StateK::StateK() {
    sha3_Init256(this);
    sha3_SetFlags(this, SHA3_FLAGS_KECCAK);
}

StateK &StateK::operator +=(const Span<const uint8_t> &data) {
    sha3_Update(this, data.data(), data.size());
    return *this;
}

StateK &StateK::operator +=(const Buffer &data) {
    data.each([&](const uint8_t *data, size_t size) {
        operator +=({data, size});
        return true;
    });

    return *this;
}

Brick<32> StateK::operator ()() const & {
    sha3_context state(*this);
    Brick<32> hash;
    memcpy(hash.data(), sha3_Finalize(&state), 32);
    return hash;
}

Brick<32> StateK::operator ()() && {
    Brick<32> hash;
    memcpy(hash.data(), sha3_Finalize(this), 32);
    return hash;
}

Brick<32> HashK(const Buffer &data) {
    StateK context;
    context += data;
    return std::move(context)();
}

Brick<64> Hash4(const Buffer &data) {
    SHA512_CTX context;
    SHA512_Init(&context);

    data.each([&](const uint8_t *data, size_t size) {
        SHA512_Update(&context, data, size);
        return true;
    });

    Brick<SHA512_DIGEST_LENGTH> hash;
    SHA512_Final(hash.data(), &context);
    return hash;
}

Brick<32> Hash2(const Buffer &data) {
    SHA256_CTX context;
    SHA256_Init(&context);

    data.each([&](const uint8_t *data, size_t size) {
        SHA256_Update(&context, data, size);
        return true;
    });

    Brick<SHA256_DIGEST_LENGTH> hash;
    SHA256_Final(hash.data(), &context);
    return hash;
}

Brick<20> Hash1(const Buffer &data) {
    SHA_CTX context;
    SHA1_Init(&context);

    data.each([&](const uint8_t *data, size_t size) {
        SHA1_Update(&context, data, size);
        return true;
    });

    Brick<SHA_DIGEST_LENGTH> hash;
    SHA1_Final(hash.data(), &context);
    return hash;
}

Brick<20> HashR(const Buffer &data) {
    RIPEMD160_CTX context;
    RIPEMD160_Init(&context);

    data.each([&](const uint8_t *data, size_t size) {
        RIPEMD160_Update(&context, data, size);
        return true;
    });

    Brick<RIPEMD160_DIGEST_LENGTH> hash;
    RIPEMD160_Final(hash.data(), &context);
    return hash;
}

Brick<16> Hash5(const Buffer &data) {
    MD5_CTX context;
    MD5_Init(&context);

    data.each([&](const uint8_t *data, size_t size) {
        MD5_Update(&context, data, size);
        return true;
    });

    Brick<MD5_DIGEST_LENGTH> hash;
    MD5_Final(hash.data(), &context);
    return hash;
}

Signature::Signature(const Brick<32> &r, const Brick<32> &s, uint8_t v) :
    r_(r), s_(s), v_(v)
{
}

Signature::Signature(const Brick<64> &data, uint8_t v) {
    std::tie(r_, s_) = Take<Brick<32>, Brick<32>>(data);
    v_ = v;

    static const uint256_t n_("115792089237316195423570985008687907852837564279074904382605163141518161494337");
    const auto s(s_.num<uint256_t>());
    if (s > n_ / 2) {
        v_ = v_ ^ 1;
        s_ = Number<uint256_t>(n_ - s);
    }
}

Signature::Signature(const Brick<65> &data) {
    std::tie(r_, s_, v_) = Take<Brick<32>, Brick<32>, Number<uint8_t>>(data);
}


static const secp256k1_context *Curve() {
    static std::unique_ptr<secp256k1_context, decltype(&secp256k1_context_destroy)> context_{secp256k1_context_create(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY), &secp256k1_context_destroy};
    return context_.get();
}

bool operator ==(const Key &lhs, const Key &rhs) {
    const auto context(Curve());
    return secp256k1_ec_pubkey_cmp(context, &lhs, &rhs) == 0;
}

Secret Generate() {
    return Random<32>();
}

Key Derive(const Secret &secret) {
    const auto context(Curve());
    Key key;
    orc_assert(secp256k1_ec_pubkey_create(context, &key, secret.data()) != 0);
    return key;
}

Key ToKey(const Region &data) {
    const auto context(Curve());
    Key key;
    orc_assert(secp256k1_ec_pubkey_parse(context, &key, data.data(), data.size()));
    return key;
}

Brick<65> ToUncompressed(const Key &key) {
    const auto context(Curve());

    Brick<65> data;
    size_t size(data.size());
    orc_assert(secp256k1_ec_pubkey_serialize(context, data.data(), &size, &key, SECP256K1_EC_UNCOMPRESSED) != 0);
    orc_assert(size == data.size());

    orc_assert(data[0] == 0x04);
    return data;
}

Brick<33> ToCompressed(const Key &key) {
    const auto context(Curve());

    Brick<33> data;
    size_t size(data.size());
    orc_assert(secp256k1_ec_pubkey_serialize(context, data.data(), &size, &key, SECP256K1_EC_COMPRESSED) != 0);
    orc_assert(size == data.size());

    orc_assert(data[0] == 0x02 || data[0] == 0x03);
    return data;
}

Brick<32> Agree(const Secret &secret, const Key &key) {
    const auto context(Curve());

    Brick<32> output;
    orc_assert(secp256k1_ecdh(context, output.data(), &key, secret.data(),
        [](unsigned char *output, const unsigned char *x32, const unsigned char *y32, void *arg) {
            memcpy(output, x32, 32);
            return 1;
        }
    , nullptr) != 0);

    return output;
}

Signature Sign(const Secret &secret, const Brick<32> &data) {
    const auto context(Curve());

    secp256k1_ecdsa_recoverable_signature internal;
    orc_assert(secp256k1_ecdsa_sign_recoverable(context, &internal, data.data(), secret.data(), nullptr, nullptr) != 0);

    Brick<64> external;
    int v;
    orc_assert(secp256k1_ecdsa_recoverable_signature_serialize_compact(context, external.data(), &v, &internal) != 0);

    return {external, Fit(Pos(v))};
}

Key Recover(const Brick<32> &data, const Signature &signature) {
    const auto context(Curve());

    secp256k1_ecdsa_recoverable_signature internal;
    const auto [combined] = Take<Brick<64>>(Tie(signature.r_, signature.s_));
    orc_assert(secp256k1_ecdsa_recoverable_signature_parse_compact(context, &internal, combined.data(), signature.v_) != 0);

    Key key;
    orc_assert(secp256k1_ecdsa_recover(context, &key, &internal, data.data()) != 0);
    return key;
}

Beam Abstract(int nid) {
    const auto object(OBJ_nid2obj(nid));
    const auto size(i2d_ASN1_OBJECT(object, nullptr));
    Beam data(size);
    uint8_t *end(data.data());
    orc_assert(i2d_ASN1_OBJECT(object, &end) == size);
    orc_assert(end - data.data() == size);
    return data;
}

Beam Abstract(const char *ln) {
    const auto nid(OBJ_ln2nid(ln));
    orc_assert(nid != NID_undef);
    return Abstract(nid);
}

size_t Length(Window &window) {
    const auto size(window.Take());
    if ((size & 0xc0) == 0)
        return size;
    size_t value(0);
    for (uint8_t i(0xc0); i != size; ++i)
        value = value << 8 | window.Take();
    return value;
}

}
