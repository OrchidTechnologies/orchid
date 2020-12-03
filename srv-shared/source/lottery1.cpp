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
#include "lottery1.hpp"
#include "parallel.hpp"
#include "sleep.hpp"
#include "structured.hpp"
#include "updater.hpp"

namespace orc {

Lottery1::Lottery1(Market market, Address contract) :
    Valve(typeid(*this).name()),

    market_(std::move(market)),
    contract_(std::move(contract))
{
}

task<void> Lottery1::Shut() noexcept {
    Valve::Stop();
    co_await Valve::Shut();
}

std::pair<Float, uint256_t> Lottery1::Credit(const uint256_t &now, const uint256_t &start, const uint128_t &range, const uint128_t &amount, const uint128_t &ratio, const uint64_t &gas) const {
    // XXX this used to use ethgasstation but now has a pretty lame gas model
    // XXX in fact I am not correctly modelling this problem at all anymore
    const auto bid((*market_.bid_)());
    return {(Float(amount) * market_.currency_.dollars_() - Float(gas * bid) * market_.currency_.dollars_()) * Float(ratio + 1) / Two128, bid};
}

task<bool> Lottery1::Check(const Address &signer, const Address &funder, const uint128_t &amount, const Address &recipient) {
    static Selector<std::tuple<uint256_t, uint256_t, uint256_t>, Address, Address, Address> read_("read");
    auto [escrow_balance, unlock_warned, bound] = co_await read_.Call(*market_.chain_, "latest", contract_, 90000, funder, signer, recipient);

    // XXX: check bound

    uint128_t escrow(escrow_balance >> 128);
    const uint128_t balance(escrow_balance);
    const uint128_t unlock(unlock_warned >> 128);
    const uint128_t warned(unlock_warned);

    if (unlock != 0) {
        orc_assert(escrow > warned);
        escrow -= warned;
    }

    if (amount > balance)
        co_return false;
    if (amount > escrow / 2)
        co_return false;
    co_return true;
}

}
