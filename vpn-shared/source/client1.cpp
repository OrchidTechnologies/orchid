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


#include "client1.hpp"
#include "chain.hpp"
#include "protocol.hpp"

namespace orc {

task<void> Client1::Submit(const Float &amount) {
    const auto commit(locked_()->commit_);
    const auto nonce(Random<32>());
    const auto issued(Timestamp());
    const auto expire(issued + 60 * 60 * 2);
    const Ticket1 ticket{commit, issued, nonce, face_, Ratio(face_, amount, market_, market_.currency_, Gas()), expire, funder_};
    const auto hash(ticket.Encode(lottery_, *market_.chain_, {}, {}));
    const auto signature(Sign(secret_, hash));
    co_await Client::Submit(hash, Tie(Command(Submit1_,
        uint8_t(signature.v_ + 27), signature.r_, signature.s_,
        ticket.commit_, ticket.nonce_,
        ticket.issued_, ticket.expire_,
        lottery_, market_.chain_->operator const uint256_t &(),
        ticket.amount_, ticket.ratio_,
        ticket.funder_
    )), amount);
}

void Client1::Invoice(const Bytes32 &id, const Buffer &data) {
    Client::Invoice(id, data);
    const auto [command, window] = Take<uint32_t, Window>(data);
    if (command != Commit1_)
        return;
    const auto [commit] = Take<Bytes32>(window);
    const auto locked(locked_());
    locked->commit_ = commit;
}

Client1::Client1(BufferDrain &drain, S<Updated<Prices>> oracle, Market market, const Address &lottery, const Secret &secret, const Address &funder, const uint128_t &face) :
    Client(drain, std::move(oracle)),
    market_(std::move(market)),
    lottery_(lottery),
    secret_(secret),
    funder_(funder),
    face_(face)
{
}

task<Client1 *> Client1::Wire(BufferSunk &sunk, S<Updated<Prices>> oracle, Market market, const Address &lottery, const Secret &secret, const Address &funder) {
    static Selector<std::tuple<uint256_t, uint256_t, uint256_t>, Address, Address, Address, Address> read_("read");
    auto [escrow_balance, unlock_warned, bound] = co_await read_.Call(*market.chain_, "latest", lottery, 90000, {}, funder, Address(Derive(secret)), 0);
    co_return &sunk.Wire<Client1>(std::move(oracle), std::move(market), lottery, secret, funder, uint128_t(escrow_balance >> 128) / 2);
}

uint128_t Client1::Face() {
    return face_;
}

uint64_t Client1::Gas() {
    return 60000;
}

}
