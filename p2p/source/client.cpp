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

#include "adapter.hpp"
#include "baton.hpp"
#include "channel.hpp"
#include "client.hpp"
#include "commands.hpp"
#include "http.hpp"
#include "link.hpp"
#include "scope.hpp"
#include "socket.hpp"
#include "trace.hpp"

namespace orc {

task<std::string> Origin::Request(const std::string &method, const URI &uri, const std::map<std::string, std::string> &headers, const std::string &data) {
    auto delayed(Connect());
    Adapter adapter(orc::Context(), std::move(delayed.link_));
    co_await delayed.code_(uri.host_, uri.port_);
    co_return co_await orc::Request(adapter, method, uri, headers, data);
}

class Actor :
    public Connection
{
  public:
    Actor() :
        Connection()
    {
    }

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
    Sink<Route<Remote>> sink_;
    cppcoro::async_manual_reset_event closed_;

  public:
    Tunnel(const S<Remote> &remote) :
        sink_([this](const Buffer &data) {
            Land(data);
        }, remote->Path())
    {
    }

    task<void> _(const std::function<task<void> (const Tag &tag)> &setup) {
        co_await setup(sink_->tag_);
    }

    ~Tunnel() {
        Task([route = sink_.Move()]() -> task<void> {
            Take<>(co_await (*route)->Call(CloseTag, route->tag_));
            // XXX: co_await closed_
        });
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

U<Route<Remote>> Remote::Path() {
    return std::make_unique<Route<Remote>>(shared_from_this());
}

task<Beam> Remote::Call(const Tag &command, const Buffer &args) {
    Beam response;
    cppcoro::async_manual_reset_event responded;
    Sink sink([&](const Buffer &data) {
        response = data;
        responded.set();
    }, Path());
    co_await sink.Send(Tie(command, args));
    co_await responded;
    co_return response;
}

task<S<Remote>> Remote::Hop(const std::string &server) {
    auto tunnel(std::make_unique<Tunnel>(shared_from_this()));
    auto backup(tunnel.get());
    auto remote(Make<Remote>(std::move(tunnel)));
    co_await backup->_([&](const Tag &tag) -> task<void> {
        auto handle(NewTag()); // XXX: this is horribly wrong
        Take<>(co_await Call(EstablishTag, Tie(handle)));
        Take<>(co_await Call(ChannelTag, Tie(handle, tag)));
        auto offer(co_await Call(OfferTag, handle));
        auto answer(co_await orc::Request("POST", {"http", server, "8080", "/"}, {}, offer.str()));
        Take<>(co_await Call(NegotiateTag, Tie(handle, Beam(answer))));
        Take<>(co_await Call(FinishTag, Tie(tag)));
    });
    co_return remote;
}

DelayedConnect Remote::Connect() {
    auto tunnel(std::make_unique<Tunnel>(shared_from_this()));
    auto backup(tunnel.get());
    return {[this, backup](const std::string &host, const std::string &port) -> task<void> {
        co_await backup->_([&](const Tag &tag) -> task<void> {
            auto endpoint(co_await Call(ConnectTag, Tie(tag, Beam(host + ":" + port))));
            Log() << "ENDPOINT " << endpoint << std::endl;
        });
    }, std::move(tunnel)};
}

task<S<Remote>> Local::Hop(const std::string &server) {
    auto client(Make<Actor>());
    auto channel(std::make_unique<Channel>(client));

    auto offer(Strip(co_await client->Offer()));
    auto answer(co_await orc::Request("POST", {"http", server, "8080", "/"}, {}, offer));

    Log() << std::endl;
    Log() << "^^^^^^^^^^^^^^^^" << std::endl;
    Log() << offer << std::endl;
    Log() << "================" << std::endl;
    Log() << answer << std::endl;
    Log() << "vvvvvvvvvvvvvvvv" << std::endl;
    Log() << std::endl;

    co_await client->Negotiate(answer);

    auto backup(channel.get());
    auto remote(Make<Remote>(std::move(channel)));
    co_await backup->_();
    co_return remote;
}

DelayedConnect Local::Connect() {
    auto socket(std::make_unique<Socket<asio::ip::tcp::socket>>());
    auto backup(socket.get());
    return {[backup](const std::string &host, const std::string &port) -> task<void> {
        co_await backup->_(host, port);
    }, std::move(socket)};
}

S<Local> GetLocal() {
    static auto local(Make<Local>());
    return local;
}

task<S<Origin>> Setup() {
    S<Origin> origin(GetLocal());

    const char *server("mac.saurik.com");
    //const char *server("localhost");

    for (unsigned i(0); i != 3; ++i) {
        auto remote(co_await origin->Hop(server));
        Identity identity;
        co_await remote->_(identity.GetCommon());
        origin = remote;
    }

    co_return origin;
}

}
