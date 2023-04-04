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
    const auto [commit, recipient] = [&]() {
        const auto locked(locked_());
        return std::make_tuple(locked->commit_, locked->recipient_);
    }();

    const auto nonce(Random<8>());
    const auto issued(Timestamp());
    const auto expire(60 * 60 * 2);
    const auto ratio(uint64_t(Two64 * Ratio(face_, amount, market_, market_.currency_, Gas()) - 1));
    const Beam receipt;
    const Ticket1 ticket{recipient, commit, issued, nonce, face_, expire, ratio, funder_, HashK(receipt)};
    const auto hash(ticket.Encode(lottery_, *market_.chain_, {}));
    const auto signature(Sign(secret_, hash));
    co_await Client::Submit(hash, Tie(Command(Submit1_,
        uint8_t(signature.v_ + 27), signature.r_, signature.s_,
        lottery_, market_.chain_->operator const uint256_t &(),
        Address(0), recipient,
        ticket.commit_, ticket.issued_, ticket.nonce_,
        ticket.amount_, ticket.expire_, ticket.ratio_,
        ticket.funder_
    )), amount);
}

void Client1::Invoice(const Bytes32 &id, const Buffer &data) {
    const auto [command, window] = Take<uint32_t, Window>(data);
    if (command != Invoice0_)
        return;

    const auto [serial, balance, lottery, chain, recipient, commit] = Take<int64_t, uint256_t, Address, uint256_t, Address, Bytes32>(window);

    const auto locked(locked_());

    // XXX: implement rollover strategy
    if (locked->serial_ < serial) {
        locked->serial_ = serial;
        locked->commit_ = commit;
        locked->recipient_ = recipient;
    }

    // XXX: this just needs to be re-designed from scratch
    Client::Invoice(id, data);
}

Client1::Client1(BufferDrain &drain, S<Updated<Prices>> oracle, Market market, Address lottery, const Secret &secret, Address funder, uint128_t face) :
    Client(drain, std::move(oracle)),
    market_(std::move(market)),
    lottery_(std::move(lottery)),
    secret_(secret),
    funder_(std::move(funder)),
    face_(std::move(face))
{
}

struct Pot {
    uint256_t amount_ = 0;
    uint256_t escrow_ = 0;
    uint256_t warned_ = 0;

    uint256_t usable() const {
        return std::min((escrow_ < warned_ ? 0 : escrow_ - warned_) / 2, amount_);
    }
};

task<Client1 &> Client1::Wire(BufferSunk &sunk, S<Updated<Prices>> oracle, Market market, const Address &lottery, const Secret &secret, const Address &funder) {
    static Selector<std::tuple<uint256_t, uint256_t>, Address, Address, Address> read_("read");
    auto [escrow_balance, unlock_warned] = co_await read_.Call(*market.chain_, "latest", lottery, 90000, {}, funder, Address(Derive(secret)));
    const Pot pot{uint128_t(escrow_balance), escrow_balance >> 128, uint128_t(unlock_warned)};
    co_return sunk.Wire<Client1>(std::move(oracle), std::move(market), lottery, secret, funder, uint128_t(pot.usable()));
}

uint128_t Client1::Face() {
    return face_;
}

uint64_t Client1::Gas() {
    return 60000;
}

Address Client1::Recipient() {
    return locked_()->recipient_;
}

}
