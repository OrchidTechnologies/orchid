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
        static const auto orchid_(Hash("Orchid.grab"));

        return Hash(Coder<
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

struct Ticket1 {
    Bytes32 commit_;
    uint64_t issued_;
    Bytes32 nonce_;
    uint128_t amount_;
    uint128_t ratio_;
    uint64_t expire_;
    Address funder_;

    uint256_t Value() const {
        return (ratio_ + uint256_t(1)) * amount_;
    }

    uint256_t Packed1() const {
        return uint256_t(expire_ - issued_) << 192 | uint256_t(ratio_ >> 64) << 128 | amount_; }
    uint256_t Packed2() const {
        return uint256_t(issued_) << 193 | uint256_t(funder_.num()) << 33; }

    template <typename ...Args_>
    Bytes32 Encode(const Address &lottery, const uint256_t &chain, const Args_ &...args, const uint32_t &salt) const {
        return Hash(Coder<
            Bytes32,
            uint256_t,
            uint256_t,
            uint256_t,
            Args_..., Address, uint256_t
        >::Encode(
            Hash(Coder<Bytes32, uint32_t>::Encode(commit_, salt)),
            uint128_t(nonce_.num<uint256_t>()),
            Packed1(),
            Packed2(),
            args..., lottery, chain
        ));
    }
};

}

#endif//ORCHID_TICKET_HPP
