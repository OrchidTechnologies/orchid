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


#include <regex>

#include <api/sctp_transport_interface.h>
#include <p2p/base/ice_transport_internal.h>
#include <pc/peer_connection_internal.h>

#include <rtc_base/async_invoker.h>
#include <rtc_base/openssl_identity.h>
#include <rtc_base/ssl_adapter.h>

#include "channel.hpp"
#include "lwip.hpp"
#include "memory.hpp"
#include "pirate.hpp"
#include "socket.hpp"
#include "trace.hpp"

namespace orc {

const Threads &Threads::Get() {
    static Threads threads;
    return threads;
}

Threads::Threads() {
    signals_ = rtc::Thread::Create();
    signals_->SetName("Orchid WebRTC Signals", nullptr);
    signals_->Start();

    working_ = rtc::Thread::Create();
    working_->SetName("Orchid WebRTC Workers", nullptr);
    working_->Start();

    _trace();
}

// XXX: should this task really be delegated to WebRTC?
// NOLINTNEXTLINE (fuchsia-statically-constructed-objects)
struct SetupSSL {
    SetupSSL() { rtc::InitializeSSL(); }
    ~SetupSSL() { rtc::CleanupSSL(); }
} setup_;

Peer::Peer(const S<Origin> &origin, Configuration configuration) :
    origin_(origin),
    peer_([&]() {
        const auto &threads(Threads::Get());

        auto factory(webrtc::CreateModularPeerConnectionFactory([&]() {
            webrtc::PeerConnectionFactoryDependencies dependencies;
            dependencies.network_thread = origin_->Thread();
            dependencies.worker_thread = threads.working_.get();
            dependencies.signaling_thread = threads.signals_.get();
            return dependencies;
        }()));

        webrtc::PeerConnectionInterface::RTCConfiguration rtc;

        if (configuration.tls_ != nullptr)
            rtc.certificates.emplace_back(std::move(configuration.tls_));

        rtc.disable_link_local_networks = true;
        rtc.sdp_semantics = webrtc::SdpSemantics::kUnifiedPlan;

        for (const auto &ice : configuration.ice_) {
            webrtc::PeerConnectionInterface::IceServer server;
            server.urls.emplace_back(ice);
            rtc.servers.emplace_back(std::move(server));
        }

        return factory->CreatePeerConnection(rtc, [&]() {
            webrtc::PeerConnectionDependencies dependencies(this);
            dependencies.allocator = origin_->Allocator();
            return dependencies;
        }());
    }())
{
}

struct Internal_ { typedef struct socket *(cricket::SctpTransport::*type); };
template struct Pirate<Internal_, &cricket::SctpTransport::sock_>;

task<struct socket *> Peer::Internal() {
    auto sctp(co_await Post([&]() -> rtc::scoped_refptr<webrtc::SctpTransportInterface> {
        return peer_->GetSctpTransport();
    }));

    orc_assert(sctp != nullptr);

    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-static-cast-downcast)
    co_return static_cast<cricket::SctpTransport *>(static_cast<webrtc::SctpTransport *>(sctp.get())->internal())->*Loot<Internal_>::pointer;
}

task<cricket::Candidate> Peer::Candidate() {
    auto sctp(co_await Post([&]() -> rtc::scoped_refptr<webrtc::SctpTransportInterface> {
        return peer_->GetSctpTransport();
    }));

    orc_assert(sctp != nullptr);

    co_return origin_->Thread()->Invoke<cricket::Candidate>(RTC_FROM_HERE, [&]() -> cricket::Candidate {
        auto dtls(sctp->dtls_transport());
        orc_assert(dtls != nullptr);
        auto ice(dtls->ice_transport());
        orc_assert(ice != nullptr);
        auto internal(ice->internal());
        orc_assert(internal != nullptr);
        auto connection(internal->selected_connection());
        orc_assert(connection != nullptr);
        return connection->remote_candidate();
    });
}

void Peer::OnIceConnectionChange(webrtc::PeerConnectionInterface::IceConnectionState state) {
    switch (state) {
        case webrtc::PeerConnectionInterface::kIceConnectionNew:
            if (Verbose)
                Log() << "OnIceConnectionChange(kIceConnectionNew)" << std::endl;
            break;
        case webrtc::PeerConnectionInterface::kIceConnectionChecking:
            if (Verbose)
                Log() << "OnIceConnectionChange(kIceConnectionChecking)" << std::endl;
            break;
        case webrtc::PeerConnectionInterface::kIceConnectionConnected:
            if (Verbose)
                Log() << "OnIceConnectionChange(kIceConnectionConnected)" << std::endl;
            break;
        case webrtc::PeerConnectionInterface::kIceConnectionCompleted:
            if (Verbose)
                Log() << "OnIceConnectionChange(kIceConnectionCompleted)" << std::endl;
            break;
        case webrtc::PeerConnectionInterface::kIceConnectionDisconnected:
            if (Verbose)
                Log() << "OnIceConnectionChange(kIceConnectionDisconnected)" << std::endl;
            break;

        case webrtc::PeerConnectionInterface::kIceConnectionFailed:
            if (Verbose)
                Log() << "OnIceConnectionChange(kIceConnectionFailed)" << std::endl;
            // this should be handled in OnStandardizedIceConnectionChange
        break;

        case webrtc::PeerConnectionInterface::kIceConnectionClosed:
            if (Verbose)
                Log() << "OnIceConnectionChange(kIceConnectionClosed)" << std::endl;
            closed_.set();
        break;

        case webrtc::PeerConnectionInterface::kIceConnectionMax:
        default:
            orc_insist(false);
        break;
    }
}

void Peer::OnStandardizedIceConnectionChange(webrtc::PeerConnectionInterface::IceConnectionState state) {
    switch (state) {
        case webrtc::PeerConnectionInterface::kIceConnectionNew:
            if (Verbose)
                Log() << "OnStandardizedIceConnectionChange(kIceConnectionNew)" << std::endl;
            break;
        case webrtc::PeerConnectionInterface::kIceConnectionChecking:
            if (Verbose)
                Log() << "OnStandardizedIceConnectionChange(kIceConnectionChecking)" << std::endl;
            break;
        case webrtc::PeerConnectionInterface::kIceConnectionConnected:
            if (Verbose)
                Log() << "OnStandardizedIceConnectionChange(kIceConnectionConnected)" << std::endl;
            break;
        case webrtc::PeerConnectionInterface::kIceConnectionCompleted:
            if (Verbose)
                Log() << "OnStandardizedIceConnectionChange(kIceConnectionCompleted)" << std::endl;
            break;
        case webrtc::PeerConnectionInterface::kIceConnectionDisconnected:
            if (Verbose)
                Log() << "OnStandardizedIceConnectionChange(kIceConnectionDisconnected)" << std::endl;
            break;

        case webrtc::PeerConnectionInterface::kIceConnectionFailed:
            if (Verbose)
                Log() << "OnStandardizedIceConnectionChange(kIceConnectionFailed)" << std::endl;

            // you can't close a PeerConnection if it is blocked in a signal
            Spawn([self = shared_from_this()]() mutable -> task<void> {
                co_await Post([self = std::move(self)]() {
                    for (auto current(self->channels_.begin()); current != self->channels_.end(); ) {
                        auto next(current);
                        ++next;
                        (*current)->Stop("kIceConnectionClosed");
                        current = next;
                    }

                    self->Stop();
                });
            });
        break;

        case webrtc::PeerConnectionInterface::kIceConnectionClosed:
            if (Verbose)
                Log() << "OnStandardizedIceConnectionChange(kIceConnectionClosed)" << std::endl;
            // this is (annoyingly) only signaled via OnIceConnectionChange
            orc_assert(false);
        break;

        case webrtc::PeerConnectionInterface::kIceConnectionMax:
        default:
            orc_insist(false);
        break;
    }
}

void Peer::OnDataChannel(rtc::scoped_refptr<webrtc::DataChannelInterface> interface) {
    Land(std::move(interface));
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
    Actor(const S<Origin> &origin, Configuration configuration) :
        Peer(origin, std::move(configuration))
    {
    }

    ~Actor() override {
_trace();
        Close();
    }
};

task<Socket> Channel::Wire(Sunk<> *sunk, const S<Origin> &origin, Configuration configuration, const std::function<task<std::string> (std::string)> &respond) {
    auto client(Make<Actor>(origin, std::move(configuration)));
    auto channel(sunk->Wire<Channel>(client));
    auto answer(co_await respond(Strip(co_await client->Offer())));
    co_await client->Negotiate(answer);
    co_await channel->Open();
    auto candidate(co_await client->Candidate());
    const auto &socket(candidate.address());
    co_return Socket(socket.ipaddr().ipv4_address(), socket.port());
}

std::string Strip(const std::string &sdp) {
    static std::regex re("\r?\na=candidate:[^\r\n]*");
    return std::regex_replace(sdp, re, "");
}

rtc::scoped_refptr<rtc::RTCCertificate> Certify() {
    return rtc::RTCCertificate::Create(U<rtc::OpenSSLIdentity>(rtc::OpenSSLIdentity::GenerateWithExpiration(
        "WebRTC", rtc::KeyParams(rtc::KT_DEFAULT), 60*60*24
    )));
}

task<std::string> Description(const S<Origin> &origin, std::vector<std::string> ice) {
    Configuration configuration;
    configuration.ice_ = std::move(ice);
    auto client(Make<Actor>(origin, std::move(configuration)));
    auto stopper(Break<Sink<Stopper>>());
    stopper->Wire<Channel>(client);
    co_return co_await client->Offer();
}

}
