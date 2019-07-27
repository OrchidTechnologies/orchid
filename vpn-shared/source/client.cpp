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

#ifndef _WIN32
#include <netdb.h>
#include <netinet/in.h>
#endif

#include <boost/random.hpp>
#include <boost/random/random_device.hpp>

#include <pc/webrtc_sdp.h>

#include <maxminddb.h>

#include "channel.hpp"
#include "client.hpp"
#include "commands.hpp"
#include "http.hpp"
#include "jsonrpc.hpp"
#include "link.hpp"
#include "trace.hpp"

#define mmdb_check(code) [&](int error) { \
    orc_assert_(error == MMDB_SUCCESS, MMDB_strerror(error)); \
}(code)

namespace orc {

class Remote :
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
    Remote(BufferDrain *drain) :
        Link(drain)
    {
    }

    ~Remote() override {
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

task<void> Server::Swing(Sunk<Secure> *sunk, const S<Origin> &origin, const std::string &host, const std::string &port) {
    auto verify([this](const rtc::OpenSSLCertificate &certificate) -> bool {
        return *remote_ == *rtc::SSLFingerprint::Create(remote_->algorithm, certificate);
    });

    auto secure(sunk->Wire<Sink<Secure>>(false, local_.get(), verify));

    socket_ = co_await origin->Hop(secure, [&](std::string offer) -> task<std::string> {
        auto answer(co_await orc::Request("POST", {"https", host, port, "/"}, {}, offer, verify));

        if (true || Verbose) {
            Log() << "Offer: " << offer << std::endl;
            Log() << "Answer: " << answer << std::endl;
        }

        co_return answer;
    });

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

        void Land(const Buffer &data) override {
            data_ = data;
            ready_.set();
        }

        void Stop(const std::string &error) override {
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

task<Socket> Server::Hop(Sunk<> *sunk, const std::function<task<std::string> (std::string)> &respond) {
    auto remote(sunk->Wire<Sink<Remote, Route<Server>>>());
    remote->Give(Path(remote));
    co_return co_await remote->Connect([&](const Tag &tag) -> task<Socket> {
        auto answer(co_await respond((co_await Call(OfferTag, tag)).str()));
        auto description((co_await Call(NegotiateTag, Tie(tag, Beam(answer)))).str());

        cricket::Candidate candidate;
        webrtc::SdpParseError error;
        orc_assert_(webrtc::SdpDeserializeCandidate("", description, &candidate, &error), "`" << error.line << "` " << error.description);

        const auto &socket(candidate.address());
        co_return Socket(socket.ipaddr().ToString(), socket.port());
    });
}

task<Socket> Server::Connect(Sunk<> *sunk, const std::string &host, const std::string &port) {
    auto remote(sunk->Wire<Sink<Remote, Route<Server>>>());
    remote->Give(Path(remote));
    co_return co_await remote->Connect([&](const Tag &tag) -> task<Socket> {
        auto [service, socket] = Take<uint16_t, Rest>(co_await Call(ConnectTag, Tie(tag, Beam(host + ":" + port))));
        co_return Socket(socket.str(), service);
    });
}

task<S<Origin>> Setup() {
    S<Origin> origin(GetLocal());

    //Endpoint endpoint({"https", "eth-ropsten.alchemyapi.io", "443", "/jsonrpc/" ORCHID_ALCHEMY});
    Endpoint endpoint({"https", "ropsten.infura.io", "443", "/v3/" ORCHID_INFURA});
    //Endpoint endpoint({"https", "api.myetherwallet.com", "443", "/rop"});
    //Endpoint endpoint({"http", "localhost", "8545", "/"});

    // https://github.com/Blockchair/Blockchair.Support/blob/master/API_DOCUMENTATION_EN.md
    // https://api.blockchair.com/ethereum/blocks

    // https://etherscan.io/apis https://ropsten.etherscan.io/apis#proxy
    // https://api.etherscan.io/api?module=proxy&action=eth_blockNumber&apikey=YourApiKeyToken
    // https://api.etherscan.io/api?module=proxy&action=eth_getBlockByNumber&tag=0x10d4f&boolean=true&apikey=YourApiKeyToken

    boost::random::independent_bits_engine<boost::mt19937, 128, uint128_t> generator;
    generator.seed(boost::random::random_device()());

    auto latest(co_await endpoint.Latest());
    //auto block(co_await endpoint.Header(latest));

    Address directory("0xd87e0ee1a59841de2ac78c17209db97e27651985");
    //Address directory("0x9170a3b999884ec3514f181ad092587c2269ff30");

    for (unsigned i(0); i != 3; ++i) {
        typedef std::tuple<std::string, std::string, U<rtc::SSLFingerprint>> Descriptor;
        auto [host, port, fingerprint] = co_await [&]() -> task<Descriptor> {
            //co_return Descriptor{"mac.saurik.com", "8082", rtc::SSLFingerprint::CreateUniqueFromRfc4572("sha-256", "A9:E2:06:F8:42:C2:2A:CC:0D:07:3C:E4:2B:8A:FD:26:DD:85:8F:04:E0:2E:90:74:89:93:E2:A5:58:53:85:15")};

            static Selector<Address, uint128_t> scan("scan");
            auto address = co_await scan.Call(endpoint, latest, directory, generator());
            orc_assert(address != 0);

            static Selector<std::tuple<uint256_t, Bytes>, Address> look("look");
            auto [time, data] = co_await look.Call(endpoint, latest, directory, address);

            Json::Value descriptor;
            Json::Reader reader;
            orc_assert(reader.parse(data.str(), descriptor, false));

            co_return Descriptor{descriptor["host"].asString(), descriptor["port"].asString(),
                rtc::SSLFingerprint::CreateUniqueFromRfc4572(descriptor["tls-algorithm"].asString(), descriptor["tls-fingerprint"].asString())};
        }();

        orc_assert(fingerprint != nullptr);
        auto server(std::make_shared<Sink<Server, Secure>>(std::move(fingerprint)));
        co_await server->Swing(server.get(), origin, host, port);
        origin = server;
    }

    co_return origin;
}

}
