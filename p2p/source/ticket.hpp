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


#ifndef ORCHID_TICKET_HPP
#define ORCHID_TICKET_HPP

#include "jsonrpc.hpp"

namespace orc {

struct Ticket {
    Bytes32 hash_;
    Bytes32 nonce_;
    Address funder_;
    uint128_t amount_;
    uint128_t ratio_;
    uint256_t start_;
    uint128_t range_;
    Address provider_;

    Builder Encode(const Bytes &receipt) const {
        return Coder<
            Bytes32, Bytes32, Address,
            uint128_t, uint128_t,
            uint256_t, uint128_t,
            Address, Bytes
        >::Encode(
            hash_, nonce_, funder_,
            amount_, ratio_,
            start_, range_,
            provider_, receipt
        );
    }

    void Build(Builder &builder, const Bytes &receipt) const {
        builder += Tie(
            hash_, nonce_, Number<uint160_t>(funder_),
            Number<uint128_t>(amount_), Number<uint128_t>(ratio_),
            Number<uint256_t>(start_), Number<uint128_t>(range_),
            Number<uint160_t>(provider_), receipt
        );
    }
};

}

#endif//ORCHID_TICKET_HPP
