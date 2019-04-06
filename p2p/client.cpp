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

#include <cppcoro/shared_task.hpp>

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

    void OnDataChannel(rtc::scoped_refptr<webrtc::DataChannelInterface> channel) override {
        _trace();
    }
};

class Tunnel :
    public Link,
    public Route
{
  private:
    cppcoro::shared_task<Tag> handle_;

  public:
    Tunnel(const H<Router> &router, const std::function<cppcoro::shared_task<Tag> (const Tag &)> &handle) :
        Route([this](const Buffer &data) {
            Land(data);
        }, router),
        handle_(handle(tag_))
    {
    }

    ~Tunnel() {
        Spawn([router = router_, handle = handle_]() -> cppcoro::task<void> {
            co_await router->Send(Tie(CloseTag, co_await handle));
            // XXX
        }());
    }

    cppcoro::task<void> _() {
        (void) co_await handle_;
    }

    cppcoro::task<void> Send(const Buffer &data) override {
        co_await router_->Send(Tie(ForwardTag, co_await handle_, data));
    }
};

cppcoro::task<Beam> Local::Request(const Tag &command, const Buffer &data) {
    auto tag(NewTag());
    co_await router_->Send(orc::Tie(command, tag, data));
    co_return Beam("");
}

cppcoro::task<H<Link>> Local::Connect(const std::string &host, const std::string &port) {
    auto tunnel(std::make_shared<Tunnel>(router_, [&](const Tag &tag) -> cppcoro::shared_task<Tag> {
        auto [handle] = orc::Take<TagSize>(co_await Request(ConnectTag, Beam(host + ":" + port)));
        co_return handle;
    }));
    co_await tunnel->_();
    co_return tunnel;
}

cppcoro::task<H<Remote>> Direct(const std::string &server) {
    auto client(std::make_shared<Client>());
    auto channel(std::make_shared<Channel>(client));

    auto offer(co_await client->Negotiation(co_await [&]() -> cppcoro::task<webrtc::SessionDescriptionInterface *> {
        rtc::scoped_refptr<CreateObserver> observer(new rtc::RefCountedObject<CreateObserver>());
        webrtc::PeerConnectionInterface::RTCOfferAnswerOptions options;
        (*client)->CreateOffer(observer, options);
        co_await *observer;
        co_return observer->description_;
    }()));

    auto answer(co_await Request("POST", {"http", server, "8080", "/"}, {}, offer));

    std::cerr << std::endl;
    std::cerr << "^^^^^^^^^^^^^^^^" << std::endl;
    std::cerr << offer << std::endl;
    std::cerr << "================" << std::endl;
    std::cerr << answer << std::endl;
    std::cerr << "vvvvvvvvvvvvvvvv" << std::endl;
    std::cerr << std::endl;

    co_await client->Negotiate("answer", answer);
    co_await *channel;
    co_return std::make_shared<Remote>(channel);
}

cppcoro::task<H<Link>> Setup(const std::string &host, const std::string &port) {
    auto remote(co_await Direct("localhost"));

    Common common;
    auto local(std::make_shared<Local>(remote, common));
    co_await local->_();

    co_return co_await local->Connect("localhost", "9090");
}

}
