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

void Client::Transfer(size_t size) {
    benefit_ += size;
    std::cout << "BENEFIT " << std::dec << benefit_ << std::endl;
    /* XXX: nerf */ return;

    if (benefit_ >= 256) {
    benefit_ -= 256;
_trace();
    Spawn([this]() -> task<void> {
        static uint256_t nonce_(0);
        auto nonce(nonce_++);

        const auto now(Timestamp());
        auto start(now + 60 * 60 * 2);

        Ticket ticket{hash_, Number<uint256_t>(nonce), funder_, 10000, uint128_t(1) << 127, start, 0, provider_};
        auto hash(Hash(ticket.Encode()));
        auto signature(Sign(secret_, Hash(Tie(Strung<std::string>("\x19""Ethereum Signed Message:\n32"), hash))));
        tickets_.try_emplace(hash, ticket, signature);

        Header header;

        Builder builder;
        Build(builder, header);
        co_await Bonded::Send(Datagram(Port_, Port_, builder));
    }); }
}

void Client::Land(Pipe *pipe, const Buffer &data) {
    if (!Datagram(data, [&](const Socket &source, const Socket &destination, Window window) {
        if (destination != Port_)
            return false;
    try {
        return false;
    } catch (const std::exception &error) {
        return true;
    } })) {
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
    benefit_(0)
{
    hash_ = Hash(Number<uint256_t>(uint256_t(0)));
}

task<void> Client::Open(const S<Origin> &origin, const std::string &url) {
    auto verify([this](const rtc::OpenSSLCertificate &certificate) -> bool {
        return *remote_ == *rtc::SSLFingerprint::Create(remote_->algorithm, certificate);
    });

    auto sunk(Wire());

    socket_ = co_await Channel::Wire(sunk, origin, [&]() {
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
