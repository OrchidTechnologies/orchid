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

#include <dlfcn.h>

#include <netdb.h>
#include <netinet/in.h>

#include <boost/random.hpp>
#include <boost/random/random_device.hpp>

#include <pc/webrtc_sdp.h>

#include <maxminddb.h>

#include "adapter.hpp"
#include "baton.hpp"
#include "channel.hpp"
#include "client.hpp"
#include "commands.hpp"
#include "connection.hpp"
#include "http.hpp"
#include "jsonrpc.hpp"
#include "link.hpp"
#include "scope.hpp"
#include "trace.hpp"

#define mmdb_check(code) [&](int error) { \
    orc_assert_(error == MMDB_SUCCESS, MMDB_strerror(error)); \
}(code)

namespace orc {

task<std::string> Origin::Request(const std::string &method, const URI &uri, const std::map<std::string, std::string> &headers, const std::string &data) {
    Sink<Adapter> adapter(orc::Context());
    co_await Connect(&adapter, uri.host_, uri.port_);
    co_return co_await orc::Request(adapter, method, uri, headers, data);
}

class Actor final :
    public Peer
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
    virtual Route<Server> *Inner() = 0;

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

    task<Socket> Connect(const std::function<task<Socket> (const Tag &tag)> &setup) {
        co_return co_await setup(Inner()->tag_);
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

static task<std::string> Answer(const std::string &offer, const std::string &host, const std::string &port, const std::function<bool (const rtc::OpenSSLCertificate &)> &verify) {
    auto answer(co_await orc::Request("POST", {"https", host, port, "/"}, {}, offer, verify));

    if (true || Verbose) {
        Log() << "Offer: " << offer << std::endl;
        Log() << "Answer: " << answer << std::endl;
    }

    co_return answer;
}

task<void> Server::Swing(Sunk<Secure> *sunk, const S<Origin> &origin, const std::string &host, const std::string &port) {
    auto verify([this](const rtc::OpenSSLCertificate &certificate) -> bool {
        return *remote_ == *rtc::SSLFingerprint::Create(remote_->algorithm, certificate);
    });

    auto secure(sunk->Wire<Sink<Secure>>(false, local_.get(), verify));
    socket_ = co_await origin->Hop(secure, host, port, verify);
    co_await secure->Connect();
}

U<Route<Server>> Server::Path(BufferDrain *drain) {
    return std::make_unique<Route<Server>>(drain, shared_from_this());
}

task<Beam> Server::Call(const Tag &command, const Buffer &args) {
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

task<Socket> Server::Hop(Sunk<> *sunk, const std::string &host, const std::string &port, const std::function<bool (const rtc::OpenSSLCertificate &)> &verify) {
    auto tunnel(sunk->Wire<Sink<Tunnel, Route<Server>>>());
    tunnel->Give(Path(tunnel));
    co_return co_await tunnel->Connect([&](const Tag &tag) -> task<Socket> {
        auto answer(co_await Answer((co_await Call(OfferTag, tag)).str(), host, port, verify));
        auto description((co_await Call(NegotiateTag, Tie(tag, Beam(answer)))).str());

        cricket::Candidate candidate;
        webrtc::SdpParseError error;
        orc_assert_(webrtc::SdpDeserializeCandidate("", description, &candidate, &error), "`" << error.line << "` " << error.description);

        const auto &socket(candidate.address());
        co_return Socket(socket.ipaddr().ToString(), socket.port());
    });
}

task<Socket> Server::Connect(Sunk<> *sunk, const std::string &host, const std::string &port) {
    auto tunnel(sunk->Wire<Sink<Tunnel, Route<Server>>>());
    tunnel->Give(Path(tunnel));
    co_return co_await tunnel->Connect([&](const Tag &tag) -> task<Socket> {
        auto [service, socket] = Take<uint16_t, Rest>(co_await Call(ConnectTag, Tie(tag, Beam(host + ":" + port))));
        co_return Socket(socket.str(), service);
    });
}

task<Socket> Local::Hop(Sunk<> *sunk, const std::string &host, const std::string &port, const std::function<bool (const rtc::OpenSSLCertificate &)> &verify) {
    auto client(Make<Actor>());
    auto channel(sunk->Wire<Channel>(client));
    auto answer(co_await Answer(Strip(co_await client->Offer()), host, port, verify));
    co_await client->Negotiate(answer);
    co_await channel->Connect();
    auto candidate(client->Candidate());
    const auto &socket(candidate.address());
    co_return Socket(socket.ipaddr().ToString(), socket.port());
}

task<Socket> Local::Connect(Sunk<> *sunk, const std::string &host, const std::string &port) {
    auto socket(sunk->Wire<Connection<asio::ip::tcp::socket>>());
    auto endpoint(co_await socket->Connect(host, port));
    co_return Socket(endpoint.address().to_string(), endpoint.port());
}

S<Local> GetLocal() {
    static auto local(Make<Local>());
    return local;
}

task<S<Origin>> Setup() {
    S<Origin> origin(GetLocal());

    //Endpoint endpoint({"https", "eth-ropsten.alchemyapi.io", "443", "/jsonrpc/" ORCHID_ALCHEMY});
    Endpoint endpoint({"https", "ropsten.infura.io", "443", "/v3/" ORCHID_INFURA});

    boost::random::independent_bits_engine<boost::mt19937, 128, uint128_t> generator;
    generator.seed(boost::random::random_device()());

    auto block(co_await endpoint.Block());

    Address directory("0xd87e0ee1a59841de2ac78c17209db97e27651985");
    //Address directory("0x9170a3b999884ec3514f181ad092587c2269ff30");

    for (unsigned i(0); i != 3; ++i) {
        static Selector<Address, uint128_t> scan("scan");
        auto address = co_await scan.Call(endpoint, block, directory, generator());
        orc_assert(address != 0);

        static Selector<std::tuple<uint256_t, Bytes>, Address> look("look");
        auto [time, data] = co_await look.Call(endpoint, block, directory, address);

        Json::Value descriptor;
        Json::Reader reader;
        orc_assert(reader.parse(data.str(), descriptor, false));

        U<rtc::SSLFingerprint> fingerprint(rtc::SSLFingerprint::CreateUniqueFromRfc4572(descriptor["tls-algorithm"].asString(), descriptor["tls-fingerprint"].asString()));
        orc_assert(fingerprint != nullptr);
        auto server(std::make_shared<Sink<Server, Secure>>(std::move(fingerprint)));
        co_await server->Swing(server.get(), origin, descriptor["host"].asString(), descriptor["port"].asString());
        origin = server;
    }

    co_return origin;
}

}
