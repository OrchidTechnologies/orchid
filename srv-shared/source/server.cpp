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

void Server::Send(const Buffer &data) {
    Spawn([this, data = Beam(data)]() -> task<void> {
        co_return co_await Inner()->Send(data);
    });
}

void Server::Land(Pipe<Buffer> *pipe, const Buffer &data) {
    if (!Datagram(data, [&](Socket source, Socket target, const Buffer &data) {
        if (target != Port_)
            return false;
        Datagram(Port_, source, Tie(), [&](const Buffer &data) {
            return Land(data);
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
