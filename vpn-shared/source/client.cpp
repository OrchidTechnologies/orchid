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
#include "market.hpp"
#include "protocol.hpp"
#include "time.hpp"

namespace orc {

static void Justin(FILE *justin, const char *name, uint8_t value, const uint256_t &data, const uint256_t &stamp = Monotonic()) {
    if (value >= 2)
        Log() << "JUSTIN " << name << " " << std::dec << data;
    Brick<16> buffer(Tie(uint64_t(stamp), uint64_t(data)));
    buffer[0] = value;
    (void) fwrite(buffer.data(), 1, buffer.size(), justin);
}

#define Justin(...) \
    do if (justin_ != nullptr) \
        Justin(justin_, __VA_ARGS__); \
    while (false)

//static const uint128_t Gwei(1000000000);
static const uint256_t Two128(uint256_t(1) << 128);

template <typename Type_>
Type_ Min(const Type_ &lhs, const Type_ &rhs) {
    return lhs < rhs ? lhs : rhs;
}

double WinRatio_(0);

task<void> Client::Submit() {
    const Header header{Magic_, Zero<32>()};
    co_await Send(Datagram(Port_, Port_, Tie(header)));
}

task<void> Client::Submit(const Bytes32 &hash, const Ticket &ticket, const Bytes &receipt, const Signature &signature) {
    const Header header{Magic_, hash};
    co_await Send(Datagram(Port_, Port_, Tie(header,
        Command(Submit_, signature.v_, signature.r_, signature.s_, ticket.Knot(lottery_, chain_, receipt))
    )));
}

task<void> Client::Submit(uint256_t amount) {
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
    const auto signature(Sign(secret_, Hash(Tie("\x19""Ethereum Signed Message:\n32", hash))));
    // XXX: this code is backwards and needs to calculate this before the other thing
    const auto [expected, price] = market_->Credit(now, start, 0, face_, ratio, Gas());
    { const auto locked(locked_());
        Justin("payment", 3, amount >> 128);
        locked->pending_.try_emplace(hash, Pending{ticket, signature, expected}); }
    co_return co_await Submit(hash, ticket, receipt, signature);
}

void Client::Transfer(size_t size, bool send) {
    { const auto locked(locked_());
    Justin("benefit", send ? 0 : 1, size);
    (send ? locked->output_ : locked->input_) += size;
    const auto updated(locked->output_ + locked->input_);
    if (updated - locked->updated_ < 1024*256)
        return;
    locked->updated_ = updated; }
    Update();
}

// XXX: the implications of when this function gets called concern me :(
cppcoro::shared_task<Bytes> Client::Ring(Address recipient) {
    if (seller_ == Address(0))
        co_return Bytes();
    static const Selector<std::tuple<Bytes>, Bytes, Address> ring_("ring");
    static const std::string latest("latest");
    co_return std::get<0>(co_await ring_.Call(endpoint_, latest, seller_, 90000, hoarded_, recipient));
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

        const auto time(Monotonic());

        Scan(window, [&, &id = id](const Buffer &data) { try {
            const auto [command, window] = Take<uint32_t, Window>(data);
            if (command != Invoice_)
                return;

            const auto [serial, balance, lottery, chain, recipient, commit] = Take<int64_t, uint256_t, Address, uint256_t, Address, Bytes32>(window);
            orc_assert(lottery == lottery_);
            orc_assert(chain == chain_);

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

                Justin("balance", 2, balance >> 128, time);
            }

            if (!id.zero()) {
                auto pending(locked->pending_.find(id));
                if (pending != locked->pending_.end()) {
                    const auto value(pending->second.ticket_.Value());
                    locked->spent_ += pending->second.expected_;
                    locked->pending_.erase(pending);
                    Justin("updated", 4, value >> 128, time);
                }
            }

            auto predicted(locked->balance_);
            for (const auto &pending : locked->pending_) {
                const auto &ticket(pending.second.ticket_);
                // XXX: subtract predicted transaction fees
                predicted += ticket.Value();
            }

            if (justin_ != nullptr)
                Log() << "JUSTIN predict " << std::dec << (predicted >> 128);

            locked->judgement_ = locked->judge_(time, locked->spent_, locked->output_ + locked->input_, (*oracle_)());

            if (prepay_ > predicted)
                nest_.Hatch([&]() noexcept { return [this, amount = uint256_t(prepay_ * 2 - predicted)]() -> task<void> {
                    co_return co_await Submit(amount); }; }, __FUNCTION__);
            else if (!locked->pending_.empty()) {
                const auto &pending(*locked->pending_.begin());
                Justin("-retry-", 5, pending.second.ticket_.Value() >> 128, time);
                nest_.Hatch([&]() noexcept { return [this, ring = locked->ring_, pending = pending]() -> task<void> {
                    co_return co_await Submit(pending.first, pending.second.ticket_, co_await ring, pending.second.signature_); }; }, __FUNCTION__);
            }
        } orc_catch({}) });
    } orc_catch({}) return true; })) {
        Pump::Land(data);
    }
}

void Client::Stop() noexcept {
    Pump::Stop();
}

Client::Client(BufferDrain &drain,
    std::string url, U<rtc::SSLFingerprint> remote,
    Endpoint endpoint, S<Market> market, S<Updated<Float>> oracle,
    const Address &lottery, const uint256_t &chain,
    const Secret &secret, const Address &funder,
    const Address &seller, const uint128_t &face,
    const char *justin
) :
    Pump(typeid(*this).name(), drain),
    local_(Certify()),
    url_(std::move(url)),
    remote_(std::move(remote)),
    endpoint_(std::move(endpoint)),
    market_(std::move(market)),
    oracle_(std::move(oracle)),
    lottery_(lottery),
    chain_(chain),
    secret_(secret),
    funder_(funder),
    seller_(seller),
    face_(face),
    prepay_(market_->Convert((*oracle_)()/1024*2)),
    justin_(justin == nullptr ? nullptr : fopen(justin, "w"))
{
}

Client::~Client() {
    if (justin_ != nullptr)
        fclose(justin_);
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
    // XXX: return task<int256> and merge Update
    const auto locked(locked_());
    return market_->Convert(locked->balance_);
}

Float Client::Judgement() {
    const auto locked(locked_());
    return locked->judgement_;
}

uint128_t Client::Face() {
    return face_;
}

uint256_t Client::Gas() {
    return seller_ == Address(0) ? 84000 /*83267*/ : 103000;
}

const std::string &Client::URL() {
    return url_;
}

Address Client::Recipient() {
    const auto locked(locked_());
    return locked->recipient_;
}

}
