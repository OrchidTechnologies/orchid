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


#ifndef ORCHID_TICKET_HPP
#define ORCHID_TICKET_HPP

#include "crypto.hpp"
#include "float.hpp"
#include "jsonrpc.hpp"

namespace orc {

static const Float Two64(uint256_t(1) << 64);
static const Float Two128(uint256_t(1) << 128);

struct Ticket0 {
    Bytes32 commit_;
    uint256_t issued_;
    Bytes32 nonce_;
    uint128_t amount_;
    uint128_t ratio_;
    uint256_t start_;
    uint128_t range_;
    Address funder_;
    Address recipient_;

    uint256_t Value() const {
        return (ratio_ + uint256_t(1)) * amount_;
    }

    Bytes32 Encode(const Address &lottery, const uint256_t &chain, const Bytes &receipt) const {
        static const auto orchid_(HashK("Orchid.grab"));

        return HashK(Coder<
            Bytes32, Bytes32,
            uint256_t, Bytes32,
            Address, uint256_t,
            uint128_t, uint128_t,
            uint256_t, uint128_t,
            Address, Address,
            Bytes
        >::Encode(
            orchid_, commit_,
            issued_, nonce_,
            lottery, chain,
            amount_, ratio_,
            start_, range_,
            funder_, recipient_,
            receipt
        ));
    }
};

typedef std::tuple<Bytes32, Bytes32, uint256_t, uint256_t, Bytes32, Bytes32> Payment1;

struct Ticket1 {
    Bytes32 commit_;
    uint64_t issued_;
    Brick<8> nonce_;
    uint128_t amount_;
    uint32_t expire_;
    uint64_t ratio_;
    Address funder_;
    Bytes32 data_;

    uint256_t Value() const {
        return (ratio_ + uint256_t(1)) * amount_;
    }

    Bytes32 Encode(const Address &lottery, const uint256_t &chain, const Address &token) const {
        return HashK(Tie(uint8_t(0x19), uint8_t(0x00), lottery, chain, token, commit_, issued_, nonce_, amount_, expire_, ratio_, funder_, data_));
    }

    auto Payment(const Bytes32 &reveal, const Signature &signature) const {
        return Payment1(data_, reveal, uint256_t(issued_) << 192 | uint256_t(nonce_.num<uint64_t>()) << 128 | amount_, uint256_t(expire_) << 225 | uint256_t(ratio_) << 161 | uint256_t(funder_.num()) << 1 | signature.v_, signature.r_, signature.s_);
    }
};

}

#endif//ORCHID_TICKET_HPP
