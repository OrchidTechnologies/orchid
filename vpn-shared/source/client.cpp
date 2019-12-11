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

unsigned WinShift_(10);

task<void> Client::Submit() {
    Header header{Magic_, Zero<32>()};
    co_await Bonded::Send(Datagram(Port_, Port_, Tie(header)));
}

task<void> Client::Submit(const Bytes32 &hash, const Ticket &ticket, const Signature &signature) {
    Header header{Magic_, hash};
    Builder builder;
    builder += Tie(Submit_, signature.v_, signature.r_, signature.s_);
    ticket.Build(builder, lottery_, chain_, receipt_);
    co_await Bonded::Send(Datagram(Port_, Port_, Tie(header, uint16_t(builder.size()), builder)));
}

void Client::Issue(uint256_t amount) {
    Spawn([this, amount = std::move(amount)]() -> task<void> {
        if (amount == 0)
            // XXX: retry existing packet
            co_return co_await Submit();

        const auto nonce(Random<32>());

        const auto now(Seconds());
        const auto start(now + 60 * 60 * 2);

        const auto [recipient, commit] = [&]() {
            const auto lock(locked_());
            return std::make_tuple(lock->recipient_, lock->commit_);
        }();

        const auto ratio(uint128_t(1) << 127 >> WinShift_);
        const Ticket ticket{commit, now, nonce, uint128_t(amount / ratio), ratio, start, 0, funder_, recipient};
        const auto hash(Hash(ticket.Encode(lottery_, chain_, receipt_)));
        const auto signature(Sign(secret_, Hash(Tie(Strung<std::string>("\x19""Ethereum Signed Message:\n32"), hash))));
        { const auto lock(locked_());
            lock->tickets_.try_emplace(hash, ticket, signature); }
        co_return co_await Submit(hash, ticket, signature);
    });
}

void Client::Transfer(size_t size) {
    { const auto lock(locked_());
    lock->benefit_ += size;
    if (lock->benefit_ > 1024*256)
        lock->benefit_ -= 1024*256;
    else
        return; }
    Issue(0);
}

void Client::Land(Pipe *pipe, const Buffer &data) {
    if (!Datagram(data, [&](const Socket &source, const Socket &destination, const Buffer &data) {
        if (destination != Port_)
            return false;
    try {
        const auto [header, window] = Take<Header, Window>(data);
        const auto &[magic, id] = header;
        orc_assert(magic == Magic_);

        Wait(Scan(window, [&, &id = id](const Buffer &data) -> task<void> { try {
            const auto [command, window] = Take<uint32_t, Window>(data);
            orc_assert(command == Invoice_);

            const auto [timestamp, balance, lottery, chain, recipient, commit] = Take<uint256_t, checked_int256_t, Address, uint256_t, Address, Bytes32>(window);
            orc_assert(lottery == lottery_);
            orc_assert(chain == chain_);

            {
                const auto lock(locked_());
                if (!id.zero())
                    lock->tickets_.erase(id);
                if (lock->timestamp_ >= timestamp)
                    co_return;
                lock->timestamp_ = timestamp;
                lock->balance_ = balance;
                lock->recipient_ = recipient;
                lock->commit_ = commit;
            }

            if (prepay_ > balance)
                Issue(uint256_t(prepay_ * 2 - balance));
        } catch (const std::exception &error) {
        } }));
    } catch (const std::exception &error) {
    } return true; })) {
        Transfer(data.size());
        Pump::Land(data);
    }
}

Client::Client(BufferDrain *drain, U<rtc::SSLFingerprint> remote, Address provider, Address lottery, uint256_t chain, const Secret &secret, Address funder) :
    Pump(drain),
    local_(Certify()),
    remote_(std::move(remote)),
    provider_(std::move(provider)),
    lottery_(std::move(lottery)),
    chain_(std::move(chain)),
    secret_(secret),
    funder_(std::move(funder)),
    prepay_(uint256_t(0xb1a2bc2ec500)<<128)
{
}

task<void> Client::Open(const S<Origin> &origin, const std::string &url) {
    const auto verify([this](const rtc::OpenSSLCertificate &certificate) -> bool {
        return *remote_ == *rtc::SSLFingerprint::Create(remote_->algorithm, certificate);
    });

    const auto bonding(Bond());

    socket_ = co_await Channel::Wire(bonding, origin, [&]() {
        Configuration configuration;
        return configuration;
    }(), [&](std::string offer) -> task<std::string> {
        const auto answer(co_await origin->Request("POST", Locator::Parse(url), {}, offer, verify));
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
