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
    Sink<Adapter> adapter(orc::Context());
    co_await Connect(&adapter, uri.host_, uri.port_);
    co_return co_await orc::Request(adapter, method, uri, headers, data);
}

class Actor final :
    public Connection
{
  protected:
    void Land(rtc::scoped_refptr<webrtc::DataChannelInterface> interface) override {
        orc_assert(false);
    }

    void Stop(const std::string &error) override {
        // XXX: how much does this matter?
_trace();
    }

  public:
    Actor() :
        Connection()
    {
    }

    virtual ~Actor() {
_trace();
        Close();
    }
};

class Tunnel :
    public Link
{
    template <typename Base_, typename Inner_, typename Drain_>
    friend class Sink;

  protected:
    virtual Route<Remote> *Inner() = 0;

    void Land(const Buffer &data) override {
        Link::Land(data);
    }

    void Stop(const std::string &error) override {
        Link::Stop(error);
    }

  public:
    Tunnel(BufferDrain *drain) :
        Link(drain)
    {
    }

    ~Tunnel() {
_trace();
    }

    task<void> _(const std::function<task<void> (const Tag &tag)> &setup) {
        co_await setup(Inner()->tag_);
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await Inner()->Send(data);
    }

    task<void> Shut() override {
        auto &inner(*Inner());
        Take<>(co_await inner->Call(CloseTag, inner.tag_));
        co_await Link::Shut();
    }
};

task<void> Remote::Swing(Sunk<Secure> *sunk, const S<Origin> &origin, const std::string &server) {
    auto secure(sunk->Wire<Sink<Secure>>(false, []() -> bool {
        // XXX: verify the certificate
_trace();
        return true;
    }));

    co_await origin->Hop(secure, server);
    co_await secure->_();
}

U<Route<Remote>> Remote::Path(BufferDrain *drain) {
    return std::make_unique<Route<Remote>>(drain, shared_from_this());
}

task<Beam> Remote::Call(const Tag &command, const Buffer &args) {
    class Result :
        public BufferDrain
    {
      private:
        Beam data_;
        std::string error_;
        cppcoro::async_manual_reset_event ready_;

      protected:
        virtual BufferDrain *Inner() = 0;

        void Land(const Buffer &data) {
            data_ = data;
            ready_.set();
        }

        void Stop(const std::string &error) {
            error_ = error;
            ready_.set();
        }

      public:
        task<Beam> Wait() {
            // XXX: retry after timeout
            co_await ready_;
            co_await Schedule();
            Inner()->Stop();
            orc_assert_(error_.empty(), error_);
            co_return std::move(data_);
        }
    };

    Sink<Result> result;

    auto path(result.Give(Path(&result)));

    co_await path->Send(Tie(command, args));
    co_return co_await result.Wait();
}

task<void> Remote::Hop(Sunk<> *sunk, const std::string &server) {
    auto tunnel(sunk->Wire<Sink<Tunnel, Route<Remote>>>());
    tunnel->Give(Path(tunnel));
    co_await tunnel->_([&](const Tag &tag) -> task<void> {
        auto offer((co_await Call(OfferTag, tag)).str());
        auto answer(co_await orc::Request("POST", {"http", server, "8080", "/"}, {}, offer));

        if (Verbose) {
            Log() << "Offer: " << offer << std::endl;
            Log() << "Answer: " << answer << std::endl;
        }

        Take<>(co_await Call(NegotiateTag, Tie(tag, Beam(answer))));
    });
}

task<void> Remote::Connect(Sunk<> *sunk, const std::string &host, const std::string &port) {
    auto tunnel(sunk->Wire<Sink<Tunnel, Route<Remote>>>());
    tunnel->Give(Path(tunnel));
    co_await tunnel->_([&](const Tag &tag) -> task<void> {
        auto endpoint(co_await Call(ConnectTag, Tie(tag, Beam(host + ":" + port))));
        Log() << "ENDPOINT " << endpoint << std::endl;
    });
}

task<void> Local::Hop(Sunk<> *sunk, const std::string &server) {
    auto client(Make<Actor>());
    auto channel(sunk->Wire<Channel>(client));

    auto offer(Strip(co_await client->Offer()));
    auto answer(co_await orc::Request("POST", {"http", server, "8080", "/"}, {}, offer));

    if (Verbose) {
        Log() << "Offer: " << offer << std::endl;
        Log() << "Answer: " << answer << std::endl;
    }

    co_await client->Negotiate(answer);
    co_await channel->_();
}

task<void> Local::Connect(Sunk<> *sunk, const std::string &host, const std::string &port) {
    auto socket(sunk->Wire<Socket<asio::ip::tcp::socket>>());
    auto endpoint(co_await socket->_(host, port));
    (void) endpoint;
}

S<Local> GetLocal() {
    static auto local(Make<Local>());
    return local;
}

task<S<Origin>> Setup() {
    S<Origin> origin(GetLocal());

    const char *server("mac.saurik.com");
    //const char *server("node.orchid.dev");
    //const char *server("localhost");

    for (unsigned i(0); i != 3; ++i) {
        // XXX: this is all wrong right now as it doesn't support multiple routes
        Identity identity;
        auto remote(std::make_shared<Sink<Remote, Secure>>(identity.GetCommon()));
        co_await remote->Swing(remote.get(), origin, server);
        origin = remote;
    }

    co_return origin;
}

}
