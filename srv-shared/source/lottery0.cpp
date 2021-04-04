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


#include "baton.hpp"
#include "duplex.hpp"
#include "json.hpp"
#include "lottery0.hpp"
#include "parallel.hpp"
#include "sleep.hpp"
#include "structured.hpp"
#include "updater.hpp"

namespace orc {

Lottery0::Lottery0(Token token, Address contract) :
    Lottery(typeid(*this).name()),
    token_(std::move(token)),
    contract_(std::move(contract))
{
}

task<void> Lottery0::Shut() noexcept {
    Valve::Stop();
    co_await Valve::Shut();
}

std::pair<Float, uint256_t> Lottery0::Credit(const uint256_t &now, const uint256_t &start, const uint128_t &range, const uint128_t &amount, const uint128_t &ratio, const uint64_t &gas) const {
    // XXX this used to use ethgasstation but now has a pretty lame gas model
    // XXX in fact I am not correctly modelling this problem at all anymore
    const auto bid((*token_.market_.bid_)());
    return {(Float(amount) * token_.currency_.dollars_() - Float(gas * bid) * token_.market_.currency_.dollars_()) * (Float(ratio) + 1) / Two128, bid};
}

task<uint128_t> Lottery0::Check_(const Address &signer, const Address &funder, const Address &recipient) {
    static const Selector<std::tuple<uint128_t, uint128_t, uint256_t, Address, Bytes32, Bytes>, Address, Address> look_("look");
    const auto [balance, escrow, unlock, verify, codehash, shared] = co_await look_.Call(*token_.market_.chain_, "latest", contract_, 90000, funder, signer);

    // XXX: check codehash/shared

    co_return unlock != 0 ? 0 : std::min(escrow / 2, balance);
}

}
