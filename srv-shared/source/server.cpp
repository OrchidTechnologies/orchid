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
    const auto amount(cashier_->Bill(data.size()) * 2);

    {
        std::unique_lock<std::mutex> lock_(mutex_);
        if (balance_ < amount) {
            _trace(); return; }
        balance_ -= amount;
        //Log() << "balance- = " << balance_ << std::endl;
    }

    Spawn([pipe, data = Beam(data)]() -> task<void> {
        co_return co_await pipe->Send(data);
    });
}

task<void> Server::Send(const Buffer &data) {
    co_return co_await Bonded::Send(data);
}

void Server::Commit() {
    const auto reveal(Random<32>());
    if (commit_ != reveals_.end())
        commit_->second.second = Seconds();
    commit_ = reveals_.try_emplace(Hash(reveal), reveal, 0).first;
}

task<void> Server::Invoice(Pipe<Buffer> *pipe, const Socket &destination, const Bytes32 &id, const Float &balance, const Bytes32 &commit) {
    const auto now(Monotonic());
    Builder builder;
    builder += Tie(Invoice_, now, cashier_->Convert(balance), cashier_->Tuple(), commit);
    Header header{Magic_, id};
    co_await pipe->Send(Datagram(Port_, destination, Tie(header, uint16_t(builder.size()), builder)));
}

task<void> Server::Invoice(Pipe<Buffer> *pipe, const Socket &destination, const Bytes32 &id) {
    const auto [balance, commit] = [&]() { std::unique_lock<std::mutex> lock_(mutex_);
        return std::make_tuple(balance_, commit_->first); }();
    co_await Invoice(pipe, destination, id, balance, commit);
}

task<void> Server::Invoice(Pipe<Buffer> *pipe, const Socket &destination, const Bytes32 &id, const Buffer &data) {
    Scan(data, [&](const Buffer &data) { try {
        const auto [command, window] = Take<uint32_t, Window>(data);
        orc_assert(command == Submit_);

        const auto [
            v, r, s,
            lottery, chain,
            commit,
            nonce, funder,
            amount, ratio,
            start, range,
            recipient, temp
        ] = Take<
            uint8_t, Brick<32>, Brick<32>,
            Address, uint256_t,
            Brick<32>,
            Brick<32>, Address,
            uint128_t, uint128_t,
            uint256_t, uint128_t,
            Address, Window
        >(window);

        // XXX: fix Coder and Selector to not require this to Beam
        const Beam receipt(temp);

        orc_assert(std::tie(lottery, chain, recipient) == cashier_->Tuple());

        const auto until(start + range);
        const auto now(Seconds());
        orc_assert(until > now);

        const uint256_t gas(100000);

        const auto credit(cashier_->Credit(now, start, until, amount * (uint256_t(ratio) + 1), gas));

        using Ticket = Coder<Address, uint256_t, Bytes32, Bytes32, Address, uint128_t, uint128_t, uint256_t, uint128_t, Address, Bytes>;
        const auto ticket(Hash(Ticket::Encode(lottery, chain, commit, nonce, funder, amount, ratio, start, range, recipient, receipt)));
        const Address signer(Recover(Hash(Tie(Strung<std::string>("\x19""Ethereum Signed Message:\n32"), ticket)), v, r, s));

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

        //Log() << "balance+ = " << balance << std::endl;

        // NOLINTNEXTLINE (clang-analyzer-core.UndefinedBinaryOperatorResult)
        if (!(Hash(Tie(reveal, nonce)).skip<16>().num<uint128_t>() <= ratio))
            return;

        { std::unique_lock<std::mutex> lock_(mutex_);
            if (commit_->first == commit) {
                Commit(); } }

        std::vector<Bytes32> old;

        static Selector<void,
            Bytes32 /*reveal*/, Bytes32 /*commit*/,
            uint8_t /*v*/, Bytes32 /*r*/, Bytes32 /*s*/,
            Bytes32 /*nonce*/, Address /*funder*/,
            uint128_t /*amount*/, uint128_t /*ratio*/,
            uint256_t /*start*/, uint128_t /*range*/,
            Address /*recipient*/, Bytes /*receipt*/,
            std::vector<Bytes32> /*old*/
        > grab("grab");

        cashier_->Send(grab, gas,
            reveal, commit,
            v, r, s,
            nonce, funder,
            amount, ratio,
            start, range,
            recipient, receipt,
            old
        );
    } catch (const std::exception &error) {
        Log() << error.what() << std::endl;
    } });

    co_await Invoice(this, destination, id);
}

void Server::Land(Pipe<Buffer> *pipe, const Buffer &data) {
    if (!Datagram(data, [&](const Socket &source, const Socket &destination, const Buffer &data) {
        if (destination != Port_)
            return false;
    try {
        const auto [header, window] = Take<Header, Window>(data);
        const auto &[magic, id] = header;
        orc_assert(magic == Magic_);

        // XXX: consider doing this work synchronously
        Spawn([this, source, id = id, data = Beam(window)]() -> task<void> {
            co_await Invoice(this, source, id, data);
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
    co_await Invoice(pipe, Port_, Zero<32>());
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
