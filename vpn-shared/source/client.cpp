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


#include <boost/multiprecision/cpp_bin_float.hpp>

#include <rtc_base/openssl_identity.h>

#include "channel.hpp"
#include "client.hpp"
#include "datagram.hpp"
#include "locator.hpp"
#include "protocol.hpp"

namespace orc {

typedef boost::multiprecision::cpp_bin_float_oct Float;

//static const uint128_t Gwei(1000000000);
static const uint256_t Two128(uint256_t(1) << 128);

template <typename Type_>
Type_ Min(const Type_ &lhs, const Type_ &rhs) {
    return lhs < rhs ? lhs : rhs;
}

double WinRatio_(0);

task<void> Client::Submit() {
    const Header header{Magic_, Zero<32>()};
    co_await Bonded::Send(Datagram(Port_, Port_, Tie(header)));
}

task<void> Client::Submit(const Bytes32 &hash, const Ticket &ticket, const Bytes &receipt, const Signature &signature) {
    const Header header{Magic_, hash};
    co_await Bonded::Send(Datagram(Port_, Port_, Tie(header,
        Command(Submit_, signature.v_, signature.r_, signature.s_, ticket.Knot(lottery_, chain_, receipt))
    )));
}

void Client::Issue(uint256_t amount) {
    nest_.Hatch([&]() noexcept { return [this, amount = std::move(amount)]() -> task<void> {
        if (amount == 0)
            // XXX: retry existing packet
            co_return co_await Submit();

        const auto [commit, recipient, ring] = [&]() {
            const auto locked(locked_());
            return std::make_tuple(locked->commit_, locked->recipient_, locked->ring_);
        }();

        const auto receipt(co_await ring);

        const auto nonce(Random<32>());

        const auto now(Timestamp());
        const auto start(now + 60 * 60 * 2);

        const uint128_t ratio(WinRatio_ == 0 ? amount / face_ : uint256_t(Float(Two128) * WinRatio_ - 1));
        const Ticket ticket{commit, now, nonce, face_, ratio, start, 0, funder_, recipient};
        const auto hash(Hash(ticket.Encode(lottery_, chain_, receipt)));
        const auto signature(Sign(secret_, Hash(Tie(Strung<std::string>("\x19""Ethereum Signed Message:\n32"), hash))));
        { const auto locked(locked_());
            locked->pending_.try_emplace(hash, ticket, signature); }
        co_return co_await Submit(hash, ticket, receipt, signature);
    }; }, __FUNCTION__);
}

void Client::Transfer(size_t size) {
    { const auto locked(locked_());
    locked->benefit_ += size;
    if (locked->benefit_ > 1024*256)
        locked->benefit_ -= 1024*256;
    else
        return; }
    Issue(0);
}

// XXX: the implications of when this function gets called concern me :(
cppcoro::shared_task<Bytes> Client::Ring(Address recipient) {
    if (seller_ == Address(0))
        co_return Bytes();
    static const Selector<Bytes, Bytes, Address> ring_("ring");
    static const std::string latest("latest");
    co_return co_await ring_.Call(endpoint_, latest, seller_, 90000, shared_, recipient);
}

void Client::Land(Pipe *pipe, const Buffer &data) {
    if (!Datagram(data, [&](const Socket &source, const Socket &destination, const Buffer &data) {
        if (destination != Port_)
            return false;
    try {
        const auto [header, window] = Take<Header, Window>(data);
        const auto &[magic, id] = header;
        orc_assert(magic == Magic_);

        Scan(window, [&, &id = id](const Buffer &data) { try {
            const auto [command, window] = Take<uint32_t, Window>(data);
            if (command != Invoice_)
                return;

            const auto [serial, balance, lottery, chain, recipient, commit] = Take<int64_t, uint256_t, Address, uint256_t, Address, Bytes32>(window);
            orc_assert(lottery == lottery_);
            orc_assert(chain == chain_);

            const auto predicted([&, &serial = serial, &balance = balance, &recipient = recipient, &commit = commit]() {
                const auto locked(locked_());

                // XXX: implement rollover strategy
                if (locked->serial_ < serial) {
                    locked->serial_ = serial;
                    locked->balance_ = Complement(balance);
                    locked->commit_ = commit;

                    if (locked->recipient_ != recipient) {
                        locked->recipient_ = recipient;
                        locked->ring_ = Ring(recipient);
                    }
                }

                if (!id.zero()) {
                    auto pending(locked->pending_.find(id));
                    if (pending != locked->pending_.end()) {
                        const auto &ticket(pending->second.first);
                        locked->spent_ += ticket.Value();
                        locked->pending_.erase(pending);
                    }
                }

                auto predicted(locked->balance_);
                for (const auto &pending : locked->pending_) {
                    const auto &ticket(pending.second.first);
                    // XXX: subtract predicted transaction fees
                    predicted += ticket.Value();
                }

                return predicted;
            }());

            if (prepay_ > predicted)
                Issue(uint256_t(prepay_ * 2 - predicted));
        } orc_catch({}) });
    } orc_catch({}) return true; })) {
        Transfer(data.size());
        Pump::Land(data);
    }
}

void Client::Stop() noexcept {
    Pump::Stop();
}

Client::Client(BufferDrain &drain, std::string url, U<rtc::SSLFingerprint> remote, Endpoint endpoint, const Address &lottery, const uint256_t &chain, const Secret &secret, const Address &funder, const Address &seller, const uint128_t &face) :
    Pump(drain),
    local_(Certify()),
    url_(std::move(url)),
    remote_(std::move(remote)),
    endpoint_(std::move(endpoint)),
    lottery_(lottery),
    chain_(chain),
    secret_(secret),
    funder_(funder),
    seller_(seller),
    face_(face),
    prepay_(uint256_t(0xb1a2bc2ec500)<<128)
{
    Pump::type_ = typeid(*this).name();
}

Client::~Client() {
orc_trace();
}

task<void> Client::Open(const S<Origin> &origin) {
    const auto verify([&](const std::list<const rtc::OpenSSLCertificate> &certificates) -> bool {
        for (const auto &certificate : certificates)
            if (*remote_ == *rtc::SSLFingerprint::Create(remote_->algorithm, certificate))
                return true;
        return false;
    });

    auto &bonding(Bond());

    socket_ = co_await Channel::Wire(bonding, origin, [&]() {
        Configuration configuration;
        configuration.tls_ = local_;
        return configuration;
    }(), [&](std::string offer) -> task<std::string> {
        const auto answer((co_await origin->Fetch("POST", Locator::Parse(url_), {}, offer, verify)).ok());
        if (true || Verbose) {
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
    Transfer(data.size());
    co_return co_await Bonded::Send(data);
}

void Client::Update() {
    Issue(0);
}

uint256_t Client::Spent() {
    const auto locked(locked_());
    orc_assert(locked->pending_.empty());
    return locked->spent_;
}

checked_int256_t Client::Balance() {
    // XXX: return task<int256> and merge Update
    const auto locked(locked_());
    return locked->balance_;
}

uint128_t Client::Face() {
    return face_;
}

}
