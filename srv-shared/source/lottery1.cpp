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
#include "lottery1.hpp"
#include "notation.hpp"
#include "parallel.hpp"
#include "sleep.hpp"
#include "structured.hpp"
#include "updater.hpp"

namespace orc {

task<uint64_t> Lottery1::Height() {
    co_return co_await market_.chain_->Height();
}

task<Pot> Lottery1::Read(uint64_t height, const Address &signer, const Address &funder, const Address &recipient) {
    static Selector<std::tuple<uint256_t, uint256_t>, Address, Address, Address> read_("read");
    auto [escrow_balance, unlock_warned] = co_await read_.Call(*market_.chain_, height, contract_, 90000, {}, funder, signer);
    // XXX: check loop for merchant
    co_return Pot{uint128_t(escrow_balance), escrow_balance >> 128, uint128_t(unlock_warned)};
}

task<void> Lottery1::Scan(uint64_t begin, uint64_t end) {
    static const auto Create_(HashK("Create(address,address,address)"));
    static const auto Update_(HashK("Update(bytes32,uint256)"));
    static const auto Delete_(HashK("Delete(bytes32,uint256)"));

    for co_await (const auto &entry : market_.chain_->Logs(begin, end, contract_))
        if (const auto &selector = entry.topics_.at(0); false) {
        } else if (selector == Create_) {
            orc_assert(entry.topics_.size() == 4);
            orc_assert(entry.data_.size() == 0);
            const Address token(entry.topics_[1].num<uint256_t>());
            orc_assert(token == Address(0));
            const Address funder(entry.topics_[2].num<uint256_t>());
            const Address signer(entry.topics_[3].num<uint256_t>());
            const auto locked(locked_());
            auto &pot(locked->pots_[Hash(signer, funder)]);
            pot.second = entry.block_;
        } else if (selector == Update_) {
            orc_assert(entry.topics_.size() == 2);
            const auto &hash(entry.topics_[1]);
            const auto [escrow, amount] = Take<uint128_t, uint128_t>(entry.data_);
            const auto locked(locked_());
            auto &pot(locked->pots_[hash]);
            if (pot.second == 0)
                continue;
            pot.second = entry.block_;
            pot.first.amount_ = amount;
            pot.first.escrow_ = escrow;
        } else if (selector == Delete_) {
            orc_assert(entry.topics_.size() == 2);
            const auto &hash(entry.topics_[1]);
            const auto [marked, unlock, warned] = Take<uint64_t, uint64_t, uint128_t>(entry.data_);
            const auto locked(locked_());
            auto &pot(locked->pots_[hash]);
            if (pot.second == 0)
                continue;
            pot.second = entry.block_;
            pot.first.warned_ = warned;
        }
}

Lottery1::Lottery1(Market market, Address contract) :
    Lottery(typeid(*this).name()),

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
    return {(Float(amount) * market_.currency_.dollars_() - Float(gas * bid) * market_.currency_.dollars_()) * (Float(ratio) + 1) / Two128, bid};
}

}
