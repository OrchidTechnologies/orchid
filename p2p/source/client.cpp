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


#include <iostream>
#include <thread>

#include "channel.hpp"
#include "client.hpp"
#include "http.hpp"
#include "link.hpp"
#include "scope.hpp"
#include "trace.hpp"

namespace orc {

class Actor :
    public Connection
{
  public:
    ~Actor() {
        _trace();
    }

    void OnChannel(U<Channel> channel) override {
        _trace();
    }
};

class Tunnel :
    public Link
{
  private:
    Sink<Route<Account$>> sink_;
    cppcoro::async_manual_reset_event closed_;

  public:
    Tunnel(const S<Account$> &account) :
        sink_(std::make_unique<Route<Account$>>(account), [this](const Buffer &data) {
            Land(data);
        })
    {
    }

    ~Tunnel() {
        Task([route = sink_.Move()]() -> task<void> {
            Take<>(co_await (*route)->Call(CloseTag, route->tag_));
            // XXX: co_await closed_
        });
    }

    task<void> _(const std::function<task<void> (const Tag &tag)> &setup) {
        co_await setup(sink_->tag_);
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await sink_->Send(data);
    }

  protected:
    void Land(const Buffer &data) {
        Link::Land(data);
        if (data.empty())
            closed_.set();
    }
};

task<Beam> Account$::Call(const Tag &command, const Buffer &args) {
    Beam response;
    cppcoro::async_manual_reset_event responded;
    Sink sink(std::make_unique<Route<Account$>>(shared_from_this()), [&](const Buffer &data) {
        response = data;
        responded.set();
    });
    co_await sink.Send(Tie(command, args));
    co_await responded;
    co_return response;
}

task<S<Account$>> Account$::Hop(const std::string &server) {
    auto tunnel(std::make_unique<Tunnel>(shared_from_this()));
    co_await tunnel->_([&](const Tag &tag) -> task<void> {
        auto handle(NewTag()); // XXX: this is horribly wrong
        Take<>(co_await Call(EstablishTag, Tie(handle)));
        Take<>(co_await Call(ChannelTag, Tie(handle, tag)));
        auto offer(co_await Call(OfferTag, handle));
        auto answer(co_await Request("POST", {"http", server, "8082", "/"}, {}, offer.str()));
        Take<>(co_await Call(NegotiateTag, Tie(handle, Beam(answer))));
        Take<>(co_await Call(FinishTag, Tie(tag)));
    });
    co_return std::make_shared<Account$>(std::move(tunnel));
}

task<U<Link>> Account$::Connect(const std::string &host, const std::string &port) {
    auto tunnel(std::make_unique<Tunnel>(shared_from_this()));
    co_await tunnel->_([&](const Tag &tag) -> task<void> {
        auto res(co_await Call(ConnectTag, Tie(tag, Beam(host + ":" + port))));
        Take<>(res);
    });
    co_return std::move(tunnel);
}

task<S<Account$>> Hop(const std::string &server) {
    auto client(std::make_shared<Actor>());
    auto channel(std::make_unique<Channel>(client));

    auto offer(co_await client->Offer());
    auto answer(co_await Request("POST", {"http", server, "8082", "/"}, {}, offer));

    std::cerr << std::endl;
    std::cerr << "^^^^^^^^^^^^^^^^" << std::endl;
    std::cerr << offer << std::endl;
    std::cerr << "================" << std::endl;
    std::cerr << answer << std::endl;
    std::cerr << "vvvvvvvvvvvvvvvv" << std::endl;
    std::cerr << std::endl;

    co_await client->Negotiate(answer);
    co_await *channel;
    co_await Schedule();
    co_return std::make_shared<Account$>(std::move(channel));
}

task<U<Link>> Setup(const std::string &host, const std::string &port) {
    S<Account$> account;

    const char *server("mac.saurik.com");
    //const char *server("localhost");

    {
        account = co_await Hop(server);
        Identity identity;
        co_await account->_(identity.GetCommon());
    }

    {
        account = co_await account->Hop(server);
        Identity identity;
        co_await account->_(identity.GetCommon());
    }

    {
        account = co_await account->Hop(server);
        Identity identity;
        co_await account->_(identity.GetCommon());
    }

    co_return co_await account->Connect(host, port);
}

}
