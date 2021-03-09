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


#include "client0.hpp"
#include "chain.hpp"
#include "protocol.hpp"

namespace orc {

// XXX: the implications of when this function gets called concern me :(
cppcoro::shared_task<Bytes> Client0::Ring(Address recipient) {
    if (seller_ == Address(0))
        co_return Bytes();
    static const Selector<std::tuple<Bytes>, Bytes, Address> ring_("ring");
    static const std::string latest("latest");
    co_return std::get<0>(co_await ring_.Call(*token_.market_.chain_, latest, seller_, 90000, hoarded_, recipient));
}

task<void> Client0::Submit(const Float &amount) {
    const auto [commit, recipient, ring] = [&]() {
        const auto locked(locked_());
        return std::make_tuple(locked->commit_, locked->recipient_, locked->ring_);
    }();

    const auto receipt(co_await ring);
    const auto nonce(Random<32>());
    const auto issued(Timestamp());
    const auto start(issued + 60 * 60 * 2);
    const auto ratio(uint128_t(Two128 * Ratio(face_, amount, token_.market_, token_.currency_, Gas()) - 1));
    const Ticket0 ticket{commit, issued, nonce, face_, ratio, start, 0, funder_, recipient};
    const auto hash(ticket.Encode(lottery_, *token_.market_.chain_, receipt));
    const auto signature(Sign(secret_, HashK(Tie("\x19""Ethereum Signed Message:\n32", hash))));

    co_await Client::Submit(hash, Tie(Command(Submit0_,
        uint8_t(signature.v_ + 27), signature.r_, signature.s_, Tie(
        ticket.commit_,
        ticket.issued_, ticket.nonce_,
        lottery_, token_.market_.chain_->operator const uint256_t &(),
        ticket.amount_, ticket.ratio_,
        ticket.start_, ticket.range_,
        ticket.funder_, ticket.recipient_,
        receipt)
    )), amount);
};

void Client0::Invoice(const Bytes32 &id, const Buffer &data) {
    Client::Invoice(id, data);

    const auto [command, window] = Take<uint32_t, Window>(data);
    if (command != Invoice0_)
        return;

    const auto [serial, balance, lottery, chain, recipient, commit] = Take<int64_t, uint256_t, Address, uint256_t, Address, Bytes32>(window);

    const auto locked(locked_());

    // XXX: implement rollover strategy
    if (locked->serial_ < serial) {
        locked->serial_ = serial;
        locked->commit_ = commit;

        if (locked->recipient_ != recipient) {
            locked->recipient_ = recipient;
            locked->ring_ = Ring(recipient);
        }
    }
}

Client0::Client0(BufferDrain &drain, S<Updated<Prices>> oracle, Token token, const Address &lottery, const Secret &secret, const Address &funder, const Address &seller, Bytes hoarded, const uint128_t &face) :
    Client(drain, std::move(oracle)),
    token_(std::move(token)),
    lottery_(lottery),
    secret_(secret),
    funder_(funder),
    seller_(seller),
    hoarded_(std::move(hoarded)),
    face_(face)
{
}

task<Client0 *> Client0::Wire(BufferSunk &sunk, S<Updated<Prices>> oracle, Token token, const Address &lottery, const Secret &secret, const Address &funder) {
    static const Selector<std::tuple<uint128_t, uint128_t, uint256_t, Address, Bytes32, Bytes>, Address, Address> look_("look");
    auto [amount, escrow, unlock, seller, codehash, hoarded] = co_await look_.Call(*token.market_.chain_, "latest", lottery, 90000, funder, Address(Derive(secret)));
    orc_assert(unlock == 0);
    co_return &sunk.Wire<Client0>(std::move(oracle), std::move(token), lottery, secret, funder, seller, std::move(hoarded), escrow / 2);
}

uint128_t Client0::Face() {
    return face_;
}

uint64_t Client0::Gas() {
    return seller_ == Address(0) ? 84000 /*83267*/ : 103000;
}

}
