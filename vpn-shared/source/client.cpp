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


#include <rtc_base/openssl_identity.h>

#include "channel.hpp"
#include "client.hpp"
#include "datagram.hpp"
#include "locator.hpp"
#include "market.hpp"
#include "protocol.hpp"

namespace orc {

template <typename Type_>
Type_ Min(const Type_ &lhs, const Type_ &rhs) {
    return lhs < rhs ? lhs : rhs;
}

void Client::Transfer(size_t size, bool send) {
    { const auto locked(locked_());
    (send ? locked->output_ : locked->input_) += size;
    const auto updated(locked->output_ + locked->input_);
    if (updated - locked->updated_ < 1024*256)
        return;
    locked->updated_ = updated; }
    Update();
}

task<void> Client::Submit() {
    const Header header{Magic_, Zero<32>()};
    co_await Send(Datagram(Port_, Port_, Tie(header)));
}

task<void> Client::Submit(const Bytes32 &ticket, const Buffer &command) {
    const Header header{Magic_, ticket};
    co_await Send(Datagram(Port_, Port_, Tie(header, command)));
}

task<void> Client::Submit(const Bytes32 &ticket, const Buffer &command, const Float &amount) {
    { const auto locked(locked_());
        locked->pending_.try_emplace(ticket, Pending{Beam(command), amount}); }
    co_await Submit(ticket, command);
}

void Client::Invoice(const Bytes32 &id, const Buffer &data) {
    const auto [command, window] = Take<uint32_t, Window>(data);
    if (command != Invoice0_)
        return;

    const auto [serial, balance, lottery, chain, recipient, commit] = Take<int64_t, uint256_t, Address, uint256_t, Address, Bytes32>(window);

    const auto locked(locked_());
    // XXX: implement rollover strategy
    if (locked->serial_ >= serial)
        return;

    const auto prices((*oracle_)());

    locked->serial_ = serial;
    locked->balance_ = Float(Complement(balance)) * prices.oxt_ / Two128;

    if (!id.zero()) {
        auto pending(locked->pending_.find(id));
        if (pending != locked->pending_.end()) {
            locked->spent_ += pending->second.amount_;
            locked->pending_.erase(pending);
        }
    }

    auto predicted(locked->balance_);
    for (const auto &pending : locked->pending_)
        locked->spent_ += pending.second.amount_;

    const auto prepay(prices.gb1_ / 1024 * 2);
    if (prepay > predicted)
        nest_.Hatch([&]() noexcept { return [this, amount = prepay * 2 - predicted]() -> task<void> {
            co_return co_await Submit(amount); }; }, __FUNCTION__);
    else if (!locked->pending_.empty())
        nest_.Hatch([&]() noexcept { return [this, pending = *locked->pending_.begin()]() -> task<void> {
            co_return co_await Submit(pending.first, pending.second.command_); }; }, __FUNCTION__);
}

void Client::Land(Pipe *pipe, const Buffer &data) {
    Transfer(data.size(), true);

    if (!Datagram(data, [&](const Socket &source, const Socket &destination, const Buffer &data) {
        if (destination != Port_)
            return false;
    try {
        const auto [header, window] = Take<Header, Window>(data);
        const auto &[magic, id] = header;
        orc_assert(magic == Magic_);

        Scan(window, [&, &id = id](const Buffer &data) { try {
            Invoice(id, data);
        } orc_catch({}) });
    } orc_catch({}) return true; })) {
        Pump::Land(data);
    }
}

void Client::Stop() noexcept {
    Pump::Stop();
}

Client::Client(BufferDrain &drain, S<Updated<Prices>> oracle) :
    Pump(typeid(*this).name(), drain),
    local_(Certify()),
    oracle_(std::move(oracle))
{
}

task<void> Client::Open(const Provider &provider, const S<Origin> &origin) {
    const auto verify([&](const std::list<const rtc::OpenSSLCertificate> &certificates) -> bool {
        for (const auto &certificate : certificates)
            if (*provider.fingerprint_ == *rtc::SSLFingerprint::Create(provider.fingerprint_->algorithm, certificate))
                return true;
        return false;
    });

    auto &bonding(Bond());

    socket_ = co_await Channel::Wire(bonding, origin, [&]() {
        Configuration configuration;
        configuration.tls_ = local_;
        return configuration;
    }(), [&](std::string offer) -> task<std::string> {
        const auto answer((co_await origin->Fetch("POST", provider.locator_, {}, offer, verify)).ok());
        if (Verbose) {
            Log() << "Offer: " << offer << std::endl;
            Log() << "Answer: " << answer << std::endl;
        }
        co_return answer;
    });
}

task<void> Client::Shut() noexcept {
    co_await nest_.Shut();
    co_await Bonded::Shut();
    co_await Pump::Shut();
}

task<void> Client::Send(const Buffer &data) {
    Transfer(data.size(), false);
    return Bonded::Send(data);
}

void Client::Update() {
    nest_.Hatch([&]() noexcept { return [this]() -> task<void> {
        co_return co_await Submit(); }; }, __FUNCTION__);
}

uint64_t Client::Benefit() {
    const auto locked(locked_());
    return locked->output_ + locked->input_;
}

Float Client::Spent() {
    const auto locked(locked_());
    orc_assert(locked->pending_.empty());
    return locked->spent_;
}

Float Client::Balance() {
    // XXX: return task<Float> and merge Update
    const auto locked(locked_());
    return locked->balance_;
}

uint128_t Ratio(const uint128_t &face, const Float &amount, const Market &market, const Currency &currency, const uint64_t &gas) {
    // XXX: this is entirely wrong, actually
    return uint128_t(Float(Two128) * amount / (Float(face) * currency.dollars_() - Float(gas * (*market.bid_)()) * market.currency_.dollars_()));
}

}
