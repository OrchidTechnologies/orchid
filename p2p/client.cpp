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

#include "client.hpp"
#include "http.hpp"
#include "link.hpp"
#include "scope.hpp"
#include "trace.hpp"
#include "webrtc.hpp"

namespace orc {

class Client :
    public Connection
{
  public:
    ~Client() {
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
    Sink<Route<Local>> sink_;
    cppcoro::async_manual_reset_event closed_;

  public:
    Tunnel(const S<Local> &local) :
        sink_(std::make_unique<Route<Local>>(local), [this](const Buffer &data) {
            Land(data);
        })
    {
    }

    ~Tunnel() {
        Spawn([route = sink_.Move()]() -> cppcoro::task<void> {
            Take<>(co_await (*route)->Call(CloseTag, route->tag_));
            // XXX: co_await closed_
        }());
    }

    cppcoro::task<void> _(const std::function<cppcoro::task<void> (const Tag &tag)> &setup) {
        (void) co_await setup(sink_->tag_);
    }

    cppcoro::task<void> Send(const Buffer &data) override {
        co_return co_await sink_->Send(data);
    }

  protected:
    void Land(const Buffer &data) {
        Link::Land(data);
        if (data.empty())
            closed_.set();
    }
};

cppcoro::task<Beam> Local::Call(const Tag &command, const Buffer &args) {
    Beam response;
    cppcoro::async_manual_reset_event responded;
    Sink sink(std::make_unique<Route<Local>>(shared_from_this()), [&](const Buffer &data) {
        response = data;
        responded.set();
    });
    co_await sink.Send(Tie(command, args));
    co_await responded;
    co_return response;
}

cppcoro::task<S<Remote>> Local::Indirect(const std::string &server) {
    auto tunnel(std::make_unique<Tunnel>(shared_from_this()));
    co_await tunnel->_([&](const Tag &tag) -> cppcoro::task<void> {
        auto handle(NewTag()); // XXX: this is horribly wrong
        auto offer(co_await Call(OfferTag, handle));
        auto answer(co_await Request("POST", {"http", server, "8080", "/"}, {}, offer.str()));
        Take<>(co_await Call(NegotiateTag, Tie(handle, Beam(answer))));
        Take<>(co_await Call(ChannelTag, Tie(handle, tag)));
    });
    co_return std::make_shared<Remote>(std::move(tunnel));
}

cppcoro::task<U<Link>> Local::Connect(const std::string &host, const std::string &port) {
    auto tunnel(std::make_unique<Tunnel>(shared_from_this()));
    co_await tunnel->_([&](const Tag &tag) -> cppcoro::task<void> {
        Take<>(co_await Call(ConnectTag, Tie(tag, Beam(host + ":" + port))));
    });
    co_return std::move(tunnel);
}

cppcoro::task<S<Remote>> Direct(const std::string &server) {
    auto client(std::make_shared<Client>());
    auto channel(std::make_unique<Channel>(client));

    auto offer(co_await client->Offer());
    auto answer(co_await Request("POST", {"http", server, "8080", "/"}, {}, offer));

    std::cerr << std::endl;
    std::cerr << "^^^^^^^^^^^^^^^^" << std::endl;
    std::cerr << offer << std::endl;
    std::cerr << "================" << std::endl;
    std::cerr << answer << std::endl;
    std::cerr << "vvvvvvvvvvvvvvvv" << std::endl;
    std::cerr << std::endl;

    co_await client->Negotiate(answer);
    co_await *channel;
    co_return std::make_shared<Remote>(std::move(channel));
}

cppcoro::task<U<Link>> Setup(const std::string &host, const std::string &port) {
    auto remote(co_await Direct("localhost"));

    Identity identity;
    auto local(std::make_shared<Local>(remote));
    co_await local->_(identity.GetCommon());

    co_return co_await local->Connect("localhost", "9090");
}

}
