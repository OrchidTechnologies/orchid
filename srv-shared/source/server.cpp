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
  private:
    S<Server> server_;

  protected:
    void Land(rtc::scoped_refptr<webrtc::DataChannelInterface> interface) override {
        auto bonding(server_->Bond());
        auto channel(bonding->Wire<Channel>(shared_from_this(), interface));

        Spawn([bonding, channel = std::move(channel), server = std::move(server_)]() -> task<void> {
            co_await channel->Open();
            co_await server->Open(bonding);
        });
    }

    void Stop(const std::string &error) override {
        self_.reset();
    }

  public:
    Incoming(S<Server> server, S<Origin> origin, std::vector<std::string> ice) :
        Peer(std::move(origin), [&]() {
            Configuration configuration;
            configuration.ice_ = std::move(ice);
            return configuration;
        }()),
        server_(std::move(server))
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
            _trace(); return; }
        balance_ -= amount; }
    Spawn([pipe, data = Beam(data)]() -> task<void> {
        co_return co_await pipe->Send(data);
    });
}

task<void> Server::Send(const Buffer &data) {
    co_return co_await Bonded::Send(data);
}

void Server::Commit() {
    auto reveal(Random<32>());
    if (commit_ != reveals_.end())
        commit_->second.second = Timestamp();
    commit_ = reveals_.try_emplace(Hash(reveal), reveal, 0).first;
}

task<void> Server::Invoice(Pipe<Buffer> *pipe, const Socket &destination, const Bytes32 &id, const Bytes32 &commit) {
    const auto now(Timestamp());
    auto balance([&]() { std::unique_lock<std::mutex> lock_(mutex_);
        return balance_; }());
    Header header{Magic_, id, Invoice_};
    co_await pipe->Send(Datagram(Port_, destination, Tie(header, now, balance, cashier_->Recipient(), commit)));
}

task<void> Server::Invoice(Pipe<Buffer> *pipe, const Socket &destination, const Bytes32 &id) {
    auto [commit] = [&]() { std::unique_lock<std::mutex> lock_(mutex_);
        return std::make_tuple(commit_->first); }();
    co_await Invoice(pipe, destination, id, commit);
}

void Server::Land(Pipe<Buffer> *pipe, const Buffer &data) {
    if (!Datagram(data, [&](const Socket &source, const Socket &destination, const Buffer &data) {
        if (destination != Port_)
            return false;
    try {
        auto [header, window] = Take<Header, Window>(data);
        auto &[magic, id, command] = header;
        orc_assert(magic == Magic_);
        orc_assert(command == Submit_);

        Spawn([this, source, id = id, data = Beam(window)]() -> task<void> {
            if (data.size() == 0)
                co_return co_await Invoice(this, source, id);

            auto [
                v, r, s,
                commit,
                nonce, funder,
                amount, ratio,
                start, range,
                target, window
            ] = Take<
                uint8_t, Brick<32>, Brick<32>,
                Brick<32>,
                Brick<32>, Address,
                uint128_t, uint128_t,
                uint256_t, uint128_t,
                Address, Window
            >(data);

            // XXX: fix Coder to not immediately convert everything into a tuple so this doesn't need to copy
            Beam receipt(window);

            using Ticket = Coder<Bytes32, Bytes32, Address, uint128_t, uint128_t, uint256_t, uint128_t, Address, Bytes>;
            const auto ticket(Hash(Ticket::Encode(commit, nonce, funder, amount, ratio, start, range, target, receipt)));
            const Address signer(Recover(Hash(Tie(Strung<std::string>("\x19""Ethereum Signed Message:\n32"), ticket)), v, r, s));

            const auto until(start + range);
            const auto now(Timestamp());
            orc_assert(until > now);

            const auto credit(amount * (uint256_t(ratio) + 1));

            const auto [reveal, balance] = [&, commit = commit]() {
                std::unique_lock<std::mutex> lock_(mutex_);
                const auto reveal(reveals_.find(commit));
                orc_assert(reveal != reveals_.end());
                const auto expire(reveal->second.second);
                orc_assert(expire == 0 || reveal->second.second + 60 > now);
                orc_assert(tickets_.emplace(until, signer, ticket).second);
                balance_ += credit;
                return std::make_tuple(reveal->second.first, balance_);
            }();

            auto next(reveal);

            // NOLINTNEXTLINE (clang-analyzer-core.UndefinedBinaryOperatorResult)
            if (Hash(Tie(reveal, nonce)).num<uint256_t>() >> 128 <= ratio) {
                { std::unique_lock<std::mutex> lock_(mutex_);
                    if (commit_->first == commit) {
                        Commit(); next = commit_->first; } }

                std::vector<Bytes32> old;

                static Selector<void,
                    Bytes32 /*reveal*/, Bytes32 /*commit*/,
                    uint8_t /*v*/, Bytes32 /*r*/, Bytes32 /*s*/,
                    Bytes32 /*nonce*/, Address /*funder*/,
                    uint128_t /*amount*/, uint128_t /*ratio*/,
                    uint256_t /*start*/, uint128_t /*range*/,
                    Address /*target*/, Bytes /*receipt*/,
                    std::vector<Bytes32> /*old*/
                > grab("grab");

                co_await cashier_->Send(grab,
                    reveal, commit,
                    v, r, s,
                    nonce, funder,
                    amount, ratio,
                    start, range,
                    target, receipt,
                    old
                );
            }

            co_return co_await Invoice(this, source, id, next);
        });
    } catch (const std::exception &error) {
    } return true; })) Bill(Inner(), data);
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
    Commit();
}

task<void> Server::Open(Pipe<Buffer> *pipe) {
    co_return co_await Invoice(pipe, Port_);
}

task<void> Server::Shut() {
    co_await Bonded::Shut();
    co_await Inner()->Shut();
}

task<std::string> Server::Respond(const std::string &offer, std::vector<std::string> ice) {
    auto incoming(Incoming::Create(self_, origin_, std::move(ice)));
    auto answer(co_await incoming->Answer(offer));
    co_return answer;
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
