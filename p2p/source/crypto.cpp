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

#include <secp256k1.h>
#include <secp256k1_ecdh.h>
#include <secp256k1_recovery.h>

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


Signature::Signature(const Brick<65> &data) {
    std::tie(r_, s_, v_) = Take<Brick<32>, Brick<32>, Number<uint8_t>>(data);
}

Signature::Signature(const Brick<64> &data, int v) {
    std::tie(r_, s_) = Take<Brick<32>, Brick<32>>(data);
    v_ = v;

    static const uint256_t n_("115792089237316195423570985008687907852837564279074904382605163141518161494337");
    auto s(s_.num<uint256_t>());
    if (s > n_ / 2) {
        v_ = v_ ^ 1;
        s_ = Number<uint256_t>(n_ - s);
    }

    v_ += 27;
}

Signature::Signature(const Brick<32> &r, const Brick<32> &s, uint8_t v) :
    r_(r),
    s_(s),
    v_(v)
{
}


static const secp256k1_context *Curve() {
    static std::unique_ptr<secp256k1_context, decltype(&secp256k1_context_destroy)> context_{secp256k1_context_create(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY), &secp256k1_context_destroy};
    return context_.get();
}

static Common Serialize(const secp256k1_context *context, secp256k1_pubkey &common) {
    std::array<uint8_t, 65> data;
    size_t size(data.size());
    orc_assert(secp256k1_ec_pubkey_serialize(context, data.data(), &size, &common, SECP256K1_EC_UNCOMPRESSED) != 0);
    orc_assert(size == data.size());

    orc_assert(data[0] == 0x04);
    return {&data[1], 64};
}

Common Commonize(const Secret &secret) {
    auto *context(Curve());
    secp256k1_pubkey common;
    orc_assert(secp256k1_ec_pubkey_create(context, &common, secret.data()) != 0);
    return Serialize(context, common);
}

Signature Sign(const Secret &secret, const Brick<32> &data) {
    auto *context(Curve());

    secp256k1_ecdsa_recoverable_signature internal;
    orc_assert(secp256k1_ecdsa_sign_recoverable(context, &internal, data.data(), secret.data(), nullptr, nullptr) != 0);

    Brick<64> external;
    int v;
    orc_assert(secp256k1_ecdsa_recoverable_signature_serialize_compact(context, external.data(), &v, &internal) != 0);

    return {external, v};
}

Common Recover(const Brick<32> &data, const Signature &signature) {
    auto *context(Curve());

    secp256k1_ecdsa_recoverable_signature internal;
    auto [combined] = Take<Brick<64>>(Tie(signature.r_, signature.s_));
    orc_assert(secp256k1_ecdsa_recoverable_signature_parse_compact(context, &internal, combined.data(), signature.v_ - 27) != 0);

    secp256k1_pubkey common;
    orc_assert(secp256k1_ecdsa_recover(context, &common, &internal, data.data()) != 0);
    return Serialize(context, common);
}

}
