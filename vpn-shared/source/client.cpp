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


#include <rtc_base/openssl_identity.h>

#include "channel.hpp"
#include "client.hpp"
#include "datagram.hpp"
#include "locator.hpp"
#include "protocol.hpp"

namespace orc {

task<void> Client::Submit() {
    Header header{Magic_, Zero<32>(), Submit_};
    co_await Bonded::Send(Datagram(Port_, Port_, Tie(header)));
}

task<void> Client::Submit(Bytes32 hash, const Ticket &ticket, const Signature &signature) {
    Header header{Magic_, hash, Submit_};
    Builder builder;
    ticket.Build(builder, receipt_);
    co_await Bonded::Send(Datagram(Port_, Port_, Tie(header, signature.v_, signature.r_, signature.s_, builder)));
}

void Client::Issue(uint256_t amount) {
    Spawn([this, amount = std::move(amount)]() -> task<void> {
        if (amount == 0)
            // XXX: retry existing packet
            co_return co_await Submit();

        static uint256_t nonce_(0);
        auto nonce(nonce_++);

        const auto now(Timestamp());
        auto start(now + 60 * 60 * 2);

        auto [recipient, commit] = [&]() {
            std::unique_lock<std::mutex> lock(mutex_);
            return std::make_tuple(recipient_, commit_);
        }();

        auto ratio(uint128_t(1) << 127 >> 12);
        Ticket ticket{commit, Number<uint256_t>(nonce), funder_, uint128_t(amount / ratio), ratio, start, 0, recipient};
        auto hash(Hash(ticket.Encode(receipt_)));
        auto signature(Sign(secret_, Hash(Tie(Strung<std::string>("\x19""Ethereum Signed Message:\n32"), hash))));
        { std::unique_lock<std::mutex> lock(mutex_);
            tickets_.try_emplace(hash, ticket, signature); }
        co_return co_await Submit(hash, ticket, signature);
    });
}

void Client::Transfer(size_t size) {
    { std::unique_lock<std::mutex> lock(mutex_);
    benefit_ += size;
    if (benefit_ > 1024*256)
        benefit_ -= 1024*256;
    else
        return; }
    Issue(0);
}

void Client::Land(Pipe *pipe, const Buffer &data) {
    if (!Datagram(data, [&](const Socket &source, const Socket &destination, const Buffer &data) {
        if (destination != Port_)
            return false;
    try { [&]() {
        auto [header, window] = Take<Header, Window>(data);
        auto &[magic, id, command] = header;
        orc_assert(magic == Magic_);

        orc_assert(command == Invoice_);

        auto [timestamp, balance, recipient, commit] = Take<uint256_t, uint256_t, Address, Bytes32>(window);

        {
            std::unique_lock<std::mutex> lock(mutex_);
            if (!id.zero())
                tickets_.erase(id);
            if (timestamp_ >= timestamp)
                return;
            timestamp_ = timestamp;
            balance_ = balance;
            recipient_ = recipient;
            commit_ = commit;
        }

        if (prepay_ > balance)
            Issue(prepay_ - balance);
    }(); } catch (const std::exception &error) {
    } return true; })) {
        Transfer(data.size());
        Pump::Land(data);
    }
}

Client::Client(BufferDrain *drain, U<rtc::SSLFingerprint> remote, Address provider, const Secret &secret, Address funder) :
    Pump(drain),
    local_(Certify()),
    remote_(std::move(remote)),
    provider_(std::move(provider)),
    secret_(secret),
    funder_(std::move(funder)),
    prepay_(uint256_t(0xb1a2bc2ec500)<<128),
    benefit_(0)
{
    commit_ = Hash(Number<uint256_t>(uint256_t(0)));
}

task<void> Client::Open(const S<Origin> &origin, const std::string &url) {
    auto verify([this](const rtc::OpenSSLCertificate &certificate) -> bool {
        return *remote_ == *rtc::SSLFingerprint::Create(remote_->algorithm, certificate);
    });

    auto bonding(Bond());

    socket_ = co_await Channel::Wire(bonding, origin, [&]() {
        Configuration configuration;
        return configuration;
    }(), [&](std::string offer) -> task<std::string> {
        auto answer(co_await origin->Request("POST", Locator::Parse(url), {}, offer, verify));
        if (true || Verbose) {
            Log() << "Offer: " << offer << std::endl;
            Log() << "Answer: " << answer << std::endl;
        }
        co_return answer;
    });
}

task<void> Client::Shut() {
    co_await Bonded::Shut();
    co_await Pump::Shut();
}

task<void> Client::Send(const Buffer &data) {
    Transfer(data.size());
    co_return co_await Bonded::Send(data);
}

}
