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


#include <api/jsep_session_description.h>
#include <pc/webrtc_sdp.h>

#include "cashier.hpp"
#include "chain.hpp"
#include "channel.hpp"
#include "croupier.hpp"
#include "crypto.hpp"
#include "datagram.hpp"
#include "defragment.hpp"
#include "local.hpp"
#include "protocol.hpp"
#include "server.hpp"
#include "spawn.hpp"
#include "ticket.hpp"
#include "time.hpp"

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
        auto &bonding(server_->Bond());
        auto &defragment(bonding.Wire<BufferSink<Defragment>>());
        auto &channel(defragment.Wire<Channel>(shared_from_this(), interface));

        Spawn([&bonding, &channel, server = std::move(server_)]() noexcept -> task<void> {
            co_await channel.Open();
            // XXX: this could fail; then what?
            co_await server->Open(bonding);
        }, __FUNCTION__);
    }

    void Stop(const std::string &error) noexcept override {
        self_.reset();
    }

  public:
    Incoming(S<Server> server, const S<Base> &base, rtc::scoped_refptr<rtc::RTCCertificate> local, std::vector<std::string> ice) :
        Peer(base, [&]() {
            Configuration configuration;
            configuration.tls_ = std::move(local);
            configuration.ice_ = std::move(ice);
            return configuration;
        }()),
        server_(std::move(server))
    {
    }

    template <typename... Args_>
    static S<Incoming> New(Args_ &&...args) {
        auto self(Make<Incoming>(std::forward<Args_>(args)...));
        self->self_ = self;
        return self;
    }

    ~Incoming() override {
        Close();
    }
};

bool Server::Bill(const Buffer &data, bool force) {
    if (cashier_ == nullptr)
        return true;

    const auto amount(cashier_->Bill(data.size()));
    const auto floor(cashier_->Bill(128*1024));

    S<Server> self;

    const auto locked(locked_());
    if (!force && locked->balance_ < amount)
        return false;

    locked->balance_ -= amount;
    ++locked->serial_;

    if (locked->balance_ >= -floor)
        return true;
    std::swap(self, self_);
    return false;
}

task<void> Server::Send(Pipe &pipe, const Buffer &data, bool force) {
    if (Bill(data, force))
        return pipe.Send(data);
    return Nop();
}

void Server::Send(Pipe &pipe, const Buffer &data) {
    nest_.Hatch([&]() noexcept { return [this, &pipe, data = Beam(data)]() -> task<void> {
        return Send(pipe, data, false); }; }, __FUNCTION__);
}

task<void> Server::Send(const Buffer &data) {
    co_return co_await Bonded::Send(data);
}

void Server::Commit(const Lock<Locked_> &locked) {
    const auto reveal(Random<32>());
    if (locked->reveal_ != locked->reveals_.end())
        locked->reveal_->second = Timestamp();
    locked->reveals_.emplace_front(reveal, 0);
    locked->reveal_ = locked->reveals_.begin();
}

Float Server::Expected(const Lock<Locked_> &locked) {
    auto balance(locked->balance_);
    for (const auto &expected : locked->expected_)
        balance += expected.second;
    return balance;
}

task<void> Server::Invoice(Pipe<Buffer> &pipe, const Socket &destination, const Bytes32 &id, uint64_t serial, const Float &balance, const Bytes32 &reveal) {
    co_return co_await Send(pipe, Datagram(Port_, destination, Tie(Header{Magic_, id}, croupier_->Invoice(serial, balance, reveal))), true);
}

task<void> Server::Invoice(Pipe<Buffer> &pipe, const Socket &destination, const Bytes32 &id) {
    const auto [serial, balance, reveal] = [&]() { const auto locked(locked_());
        return std::make_tuple(locked->serial_, Expected(locked), locked->reveal_->first); }();
    co_await Invoice(pipe, destination, id, serial, balance, reveal);
}

void Server::Submit0(Pipe<Buffer> *pipe, const Socket &source, const Bytes32 &id, const Buffer &data) {
    const auto [
        v, r, s,
        commit,
        issued, nonce,
        contract, chain,
        amount, ratio,
        start, range,
        funder, recipient,
    window] = Take<
        uint8_t, Brick<32>, Brick<32>,
        Bytes32,
        uint256_t, Bytes32,
        Address, uint256_t,
        uint128_t, uint128_t,
        uint256_t, uint128_t,
        Address, Address,
    Window>(data);

    // XXX: fix Coder and Selector to not require this to Beam
    const Beam receipt(window);

    const auto until(start + range);
    const auto now(Timestamp());
    orc_assert(until > now);

    const auto &lottery(croupier_->Find0(contract, chain, recipient));
    const uint64_t gas(receipt.size() == 0 ? 84000 /*83267*/ : 103000);
    const auto [expected, price] = lottery->Credit(now, start, range, amount, ratio, gas);
    if (expected <= 0)
        return;

    const auto digest(Ticket0{commit, issued, nonce, amount, ratio, start, range, funder, recipient}.Encode(contract, chain, receipt));
    const Address signer(Recover(HashK(Tie("\x19""Ethereum Signed Message:\n32", digest)), v, r, s));

    const auto [reveal, winner] = ({
        const auto locked(locked_());

        if (issued < locked->issued_)
            return;
        auto &nonces(locked->nonces_);
        if (!nonces.emplace(issued, nonce, signer).second)
            return;
        while (nonces.size() > horizon_) {
            const auto oldest(nonces.begin());
            orc_assert(oldest != nonces.end());
            locked->issued_ = std::get<0>(*oldest) + 1;
            nonces.erase(oldest);
        }

        const auto reveal([&, &commit = commit]() {
            for (const auto &reveal : locked->reveals_)
                if (HashK(reveal.first) == commit) {
                    const auto &expire(reveal.second);
                    orc_assert(expire == 0 || expire + 60 > now);
                    return reveal.first;
                }
        orc_assert(false); }());

        orc_assert(locked->expected_.emplace(digest, expected).second);
        ++locked->serial_;

        // NOLINTNEXTLINE (clang-analyzer-core.UndefinedBinaryOperatorResult)
        const auto winner(HashK(Tie(reveal, issued, nonce)).skip<16>().num<uint128_t>() <= ratio);
        if (winner && locked->reveal_->first == commit)
            Commit(locked);
    std::make_tuple(reveal, winner); });

    // XXX: the C++ prohibition on automatic capture of a binding name because it isn't a "variable" is ridiculous
    // NOLINTNEXTLINE (clang-analyzer-optin.performance.Padding)
    nest_.Hatch([&, &commit = commit, &issued = issued, &nonce = nonce, &v = v, &r = r, &s = s, &amount = amount, &ratio = ratio, &start = start, &range = range, &funder = funder, &recipient = recipient, &reveal = reveal, &winner = winner]() noexcept { return [=]() noexcept -> task<void> { try {
        const auto usable(co_await lottery->Check(signer, funder, recipient));
        const auto valid(usable >= amount);

        {
            const auto locked(locked_());
            const auto expected(locked->expected_.find(digest));
            orc_assert(expected != locked->expected_.end());
            if (valid)
                locked->balance_ += expected->second;
            else
                ++locked->serial_;
            locked->expected_.erase(expected);
        }

        if (!valid) {
            co_await Invoice(*this, source);
            co_return;
        } else if (!winner)
            co_return;

        std::vector<Bytes32> old;

        lottery->Send(croupier_->hack(),
            reveal, commit,
            issued, nonce,
            v, r, s,
            amount, ratio,
            start, range,
            funder, recipient,
            receipt, old
        );
    } orc_catch({}) }; }, __FUNCTION__);
}

void Server::Submit1(Pipe<Buffer> *pipe, const Socket &source, const Bytes32 &id, const Buffer &data) {
    const auto [
        v, r, s,
        contract, chain,
        token, recipient,
        commit, issued, nonce,
        amount, expire, ratio,
        funder, window
    ] = Take<
        uint8_t, Brick<32>, Brick<32>,
        Address, uint256_t,
        Address, Address,
        Brick<32>, uint64_t, Brick<8>,
        uint128_t, uint32_t, uint64_t,
        Address, Window
    >(data);

    // XXX: fix Coder and Selector to not require this to Beam
    const Beam receipt(window);

    orc_assert_(recipient == croupier_->Recipient(), recipient << " != " << croupier_->Recipient() << " in " << data);

    const auto now(Timestamp());
    orc_assert(issued + expire > now);

    const auto &lottery(croupier_->Find1(contract, chain));
    const uint64_t gas(60000);
    const auto [expected, price] = lottery->Credit(now, issued + expire, 0, amount, uint128_t(ratio) << 64, gas);
    if (expected <= 0)
        return;

    const Ticket1 ticket{recipient, commit, issued, nonce, amount, expire, ratio, funder, HashK(receipt)};
    const auto digest(ticket.Encode(contract, chain, {}));
    const Signature signature(r, s, v - 27);
    const Address signer(Recover(digest, signature));

    //Log() << std::dec << std::fixed << std::setprecision(16) << recipient << "<-" << funder << "/" << signer << " " << amount << " " << ratio << " " << issued << nonce << " " << expected << " " << locked_()->balance_ << std::endl;

    const auto [reveal, winner] = ({
        const auto locked(locked_());

        if (issued < locked->issued_)
            return;
        auto &nonces(locked->nonces_);
        if (!nonces.emplace(issued, Tie(Zero<24>(), nonce), signer).second)
            return;
        while (nonces.size() > horizon_) {
            const auto oldest(nonces.begin());
            orc_assert(oldest != nonces.end());
            locked->issued_ = std::get<0>(*oldest) + 1;
            nonces.erase(oldest);
        }

        const auto reveal([&, &commit = commit]() {
            for (const auto &reveal : locked->reveals_)
                if (HashK(reveal.first) == commit) {
                    const auto &expire(reveal.second);
                    orc_assert(expire == 0 || expire + 60 > now);
                    return reveal.first;
                }
        orc_assert(false); }());

        orc_assert(locked->expected_.emplace(digest, expected).second);
        ++locked->serial_;

        // NOLINTNEXTLINE (clang-analyzer-core.UndefinedBinaryOperatorResult)
        const auto winner(HashK(Tie(reveal, issued, nonce)).skip<24>().num<uint64_t>() <= ratio);
        if (winner && locked->reveal_->first == commit)
            Commit(locked);
    std::make_tuple(reveal, winner); });

    // XXX: the C++ prohibition on automatic capture of a binding name because it isn't a "variable" is ridiculous
    // NOLINTNEXTLINE (clang-analyzer-optin.performance.Padding)
    nest_.Hatch([&, &amount = amount, &funder = funder, &recipient = recipient, &reveal = reveal, &winner = winner]() noexcept { return [=]() noexcept -> task<void> { try {
        const auto usable(co_await lottery->Check(signer, funder, recipient));
        const auto valid(usable >= amount);

        {
            const auto locked(locked_());
            const auto expected(locked->expected_.find(digest));
            orc_assert(expected != locked->expected_.end());
            if (valid)
                locked->balance_ += expected->second;
            else
                ++locked->serial_;
            locked->expected_.erase(expected);
        }

        if (!valid) {
            co_await Invoice(*this, source);
            co_return;
        } else if (!winner)
            co_return;

        lottery->Send(croupier_->hack(), recipient, ticket.Payment(reveal, signature));
    } orc_catch({}) }; }, __FUNCTION__);
}

void Server::Land(Pipe<Buffer> *pipe, const Buffer &data) { orc_ignore({
    if (Bill(data, true) && !Datagram(data, [&](const Socket &source, const Socket &destination, const Buffer &data) {
        if (destination != Port_)
            return false;
        if (croupier_ == nullptr)
            return true;

        nest_.Hatch([&]() noexcept { return [this, source, data = Beam(data)]() -> task<void> {
            const auto [header, window] = Take<Header, Window>(data);
            const auto &[magic, id] = header;
            orc_assert(magic == Magic_);

            Scan(window, [&, &id = id](const Buffer &data) { try {
                const auto [command, window] = Take<uint32_t, Window>(data);
                if (false);
                else if (command == Submit0_)
                    Submit0(this, source, id, window);
                else if (command == Submit1_)
                    Submit1(this, source, id, window);
            } orc_catch({}) });

            co_await Invoice(*this, source, id);
        }; }, __FUNCTION__);

        return true;
    })) Send(Inner(), data);
}); }

void Server::Stop() noexcept {
    Valve::Stop();
    self_.reset();
}

void Server::Land(const Buffer &data) {
    if (Bill(data, true))
        Send(*this, data);
}

void Server::Stop(const std::string &error) noexcept {
    orc_insist_(error.empty(), error);
}

Server::Server(S<Cashier> cashier, S<Croupier> croupier) :
    Valve(typeid(*this).name()),
    local_(Certify()),
    cashier_(std::move(cashier)),
    croupier_(std::move(croupier))
{
    const auto locked(locked_());
    Commit(locked);
}

task<void> Server::Open(Pipe<Buffer> &pipe) {
    if (cashier_ != nullptr)
        co_await Invoice(pipe, Port_);
}

task<void> Server::Shut() noexcept {
    co_await nest_.Shut();
    *co_await Parallel(Bonded::Shut(), Sunken::Shut());
    co_await Valve::Shut();
}

task<std::string> Server::Respond(const S<Base> &base, const std::string &offer, std::vector<std::string> ice) {
    auto incoming(co_await Post([&]() { return Incoming::New(self_, base, local_, std::move(ice)); }, RTC_FROM_HERE));
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
