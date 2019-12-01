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


#include <api/jsep_session_description.h>
#include <pc/webrtc_sdp.h>

#include "channel.hpp"
#include "datagram.hpp"
#include "local.hpp"
#include "protocol.hpp"
#include "server.hpp"

namespace orc {

class Incoming final :
    public Peer
{
  private:
    S<Incoming> self_;
    Sunk<> *sunk_;

  protected:
    void Land(rtc::scoped_refptr<webrtc::DataChannelInterface> interface) override {
        auto channel(sunk_->Wire<Channel>(shared_from_this(), interface));

        Spawn([channel]() -> task<void> {
            co_await channel->Connect();
        });
    }

    void Stop(const std::string &error) override {
        self_.reset();
    }

  public:
    Incoming(Sunk<> *sunk, S<Origin> origin, std::vector<std::string> ice) :
        Peer(std::move(origin), [&]() {
            Configuration configuration;
            configuration.ice_ = std::move(ice);
            return configuration;
        }()),
        sunk_(sunk)
    {
    }

    template <typename... Args_>
    static S<Incoming> Create(Args_ &&...args) {
        auto self(Make<Incoming>(std::forward<Args_>(args)...));
        self->self_ = self;
        return self;
    }

    ~Incoming() override {
_trace();
        Close();
    }
};

void Server::Bill(Pipe *pipe, const Buffer &data) {
    uint256_t amount(cashier_->Bill(data.size()));
    { std::unique_lock<std::mutex> lock_(mutex_);
        if (balance_ < amount) {
            _trace(); /* XXX: nerf return; */ }
        balance_ -= amount; }
    Spawn([pipe, data = Beam(data)]() -> task<void> {
        co_return co_await pipe->Send(data);
    });
}

task<void> Server::Send(const Buffer &data) {
    co_return co_await Bonded::Send(data);
}

void Server::Seed() {
    auto seed(Random<32>());
    if (hash_ != seeds_.end())
        hash_->second.second = Timestamp();
    hash_ = seeds_.try_emplace(Hash(seed), seed, 0).first;
}

void Server::Land(Pipe<Buffer> *pipe, const Buffer &data) {
    if (!Datagram(data, [&](const Socket &source, const Socket &destination, const Buffer &data) {
        if (destination != Port_)
            return false;
    try {
        auto [header, window] = Take<Header, Window>(data);
        auto &[magic] = header;
        orc_assert(magic == Magic_);

        Spawn([this, source, data = Beam(window)]() -> task<void> {
            auto [v, r, s, hash, nonce, funder, amount, ratio, start, range, target, receipt] = Take<uint8_t, Brick<32>, Brick<32>, Brick<32>, Brick<32>, Address, uint128_t, uint128_t, uint256_t, uint128_t, Address, Window>(data);

            using Ticket = Coder<Bytes32, Bytes32, Address, uint128_t, uint128_t, uint256_t, uint128_t, Address, Bytes>;
            // XXX: fix Coder to not immediately convert everything into a tuple so this doesn't need to call Beam(receipt)
            const auto ticket(Hash(Ticket::Encode(hash, nonce, funder, amount, ratio, start, range, target, Beam(receipt))));
            const Address signer(Recover(Hash(Tie(Strung<std::string>("\x19""Ethereum Signed Message:\n32"), ticket)), v, r, s));

            const auto until(start + range);
            const auto now(Timestamp());
            orc_assert(until > now);

            const auto credit(amount * (uint256_t(ratio) + 1));

            auto seed([&, hash = hash]() {
                std::unique_lock<std::mutex> lock_(mutex_);
                const auto seed(seeds_.find(hash));
                orc_assert(seed != seeds_.end());
                orc_assert(seed->second.second + 60 < now);
                orc_assert(tickets_.emplace(until, signer, ticket).second);
                balance_ += credit;
                return seed->second.first;
            }());

            // NOLINTNEXTLINE (clang-analyzer-core.UndefinedBinaryOperatorResult)
            if (Hash(Tie(seed, nonce)).num<uint256_t>() >> 128 <= ratio) {
                { std::unique_lock<std::mutex> lock_(mutex_);
                    if (hash_->first == hash)
                        Seed(); }

                std::vector<Bytes32> old;

                static Selector<void,
                    Bytes32 /*seed*/, Bytes32 /*hash*/,
                    uint8_t /*v*/, Bytes32 /*r*/, Bytes32 /*s*/,
                    Bytes32 /*nonce*/, Address /*funder*/,
                    uint128_t /*amount*/, uint128_t /*ratio*/,
                    uint256_t /*start*/, uint128_t /*range*/,
                    Address /*target*/, Bytes /*receipt*/,
                    std::vector<Bytes32> /*old*/
                > grab("grab");

                co_await cashier_->Send(grab,
                    seed, hash,
                    v, r, s,
                    nonce, funder,
                    amount, ratio,
                    start, range,
                    target, Beam(),
                    old
                );
            }

            auto packet(Tie());
            co_await Bonded::Send(Datagram(Port_, source, packet));
        });

        return true;
    } catch (const std::exception &error) {
        return true;
    } })) Bill(Inner(), data);
}

void Server::Land(const Buffer &data) {
    Bill(this, data);
}

void Server::Stop(const std::string &error) {
}

Server::Server(S<Origin> origin, S<Cashier> cashier) :
    origin_(std::move(origin)),
    cashier_(std::move(cashier)),
    balance_(0)
{
    Seed();
}

task<void> Server::Shut() {
    co_await Bonded::Shut();
    co_await Inner()->Shut();
}

task<std::string> Server::Respond(const std::string &offer, std::vector<std::string> ice) {
    auto incoming(Incoming::Create(Wire(), origin_, std::move(ice)));
    auto answer(co_await incoming->Answer(offer));
    co_return Filter(true, answer);
}

std::string Filter(bool answer, const std::string &serialized) {
    webrtc::JsepSessionDescription jsep(answer ? webrtc::SdpType::kAnswer : webrtc::SdpType::kOffer);
    webrtc::SdpParseError error;
    orc_assert(webrtc::SdpDeserialize(serialized, &jsep, &error));

    auto description(jsep.description());
    orc_assert(description != nullptr);

    std::vector<cricket::Candidate> privates;

    for (size_t i(0); ; ++i) {
        auto ices(jsep.candidates(i));
        if (ices == nullptr)
            break;
        for (size_t i(0), e(ices->count()); i != e; ++i) {
            auto ice(ices->at(i));
            orc_assert(ice != nullptr);
            const auto &candidate(ice->candidate());
            if (candidate.address().IsPrivateIP())
                privates.push_back(candidate);
        }
    }

    for (auto &p : privates)
        p.set_transport_name("0");
    orc_assert(jsep.RemoveCandidates(privates) == privates.size());

    return webrtc::SdpSerialize(jsep);
}

}
