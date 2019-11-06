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


#include "channel.hpp"
#include "datagram.hpp"
#include "local.hpp"
#include "port.hpp"
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
    Incoming(Sunk<> *sunk, std::vector<std::string> ice) :
        Peer([&]() {
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

void Server::Seed() {
    //auto seed(Random<32>());
    Bytes32 seed(Number<uint256_t>(uint256_t(0)));
    hash_ = Hash(seed);
    seeds_.emplace(hash_, seed);
}

void Server::Send(const Buffer &data) {
    Spawn([this, data = Beam(data)]() -> task<void> {
        co_return co_await Inner()->Send(data);
    });
}

using Ticket = Coder<Bytes32, Bytes32, uint256_t, uint128_t, uint128_t, uint256_t, Address, Address>;

void Server::Land(Pipe<Buffer> *pipe, const Buffer &data) {
    if (!Datagram(data, [&](Socket source, Socket destination, const Buffer &data) {
        if (destination != Port_)
            return false;

        auto [hash, nonce, start, range, amount, ratio, funder, target, v, r, s] = Take<Brick<32>, Brick<32>, uint256_t, Pad<16>, uint128_t, Pad<16>, uint128_t, uint256_t, Pad<12>, uint160_t, Pad<12>, uint160_t, Pad<31>, Number<uint8_t>, Brick<32>, Brick<32>>(data);
        Signature signature(std::move(r), std::move(s), v);

        Spawn([this, source = std::move(source), hash = std::move(hash), nonce = std::move(nonce), start = std::move(start), range = std::move(range), amount = std::move(amount), ratio = std::move(ratio), funder = Address(std::move(funder)), target = Address(std::move(target)), signature = std::move(signature)]() -> task<void> {
            auto ticket(Ticket::Encode(hash, nonce, start, range, amount, ratio, funder, target));
            auto signer(Recover(signature, Hash(Tie(Strung<std::string>("\x19""Ethereum Signed Message:\n32"), Hash(ticket)))));
            (void) signer;

            auto seed([&]() {
                std::unique_lock<std::mutex> lock_;
                auto seed(seeds_.find(hash));
                orc_assert(seed != seeds_.end());
                return seed->second;
            }());

            auto won(Hash(Tie(seed, nonce)).num<uint256_t>() <= ratio);
            if (won) {
                std::unique_lock<std::mutex> lock_;
                if (hash_ == hash)
                    Seed();
            }

            //auto packet(Tie());
            //co_await Bonded::Send(Datagram(Port_, source, packet));

            if (won) {
                std::vector<Bytes32> old;
                static Selector<void, Bytes32, Bytes32, Bytes32, uint256_t, uint128_t, uint128_t, uint256_t, Address, Address, uint8_t, Bytes32, Bytes32, std::vector<Bytes32>> grab("grab");
                co_await grab.Send(endpoint_, target, lottery_, seed, hash, nonce, start, range, amount, ratio, funder, target, signature.v_, signature.r_, signature.s_, old);
            }
        });

        return true;
    })) Send(data);
}

void Server::Land(const Buffer &data) {
    Spawn([this, data = Beam(data)]() -> task<void> {
        co_return co_await Bonded::Send(data);
    });
}

void Server::Stop(const std::string &error) {
}

Server::Server(Locator locator, Address lottery) :
    endpoint_(GetLocal(), std::move(locator)),
    lottery_(std::move(lottery))
{
    Seed();
}

task<void> Server::Shut() {
    co_await Bonded::Shut();
    co_await Inner()->Shut();
}

task<std::string> Server::Respond(const std::string &offer, std::vector<std::string> ice) {
    auto incoming(Incoming::Create(Wire(), std::move(ice)));
    auto answer(co_await incoming->Answer(offer));
    //answer = std::regex_replace(std::move(answer), std::regex("\r?\na=candidate:[^ ]* [^ ]* [^ ]* [^ ]* 10\\.[^\r\n]*"), "")
    co_return answer;
}

}
