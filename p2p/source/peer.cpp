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


#include <pc/sctp_transport.h>

#include <rtc_base/openssl_identity.h>
#include <rtc_base/ssl_adapter.h>

#include "channel.hpp"
#include "peer.hpp"
#include "pirate.hpp"
#include "spawn.hpp"

namespace orc {

// XXX: should this task really be delegated to WebRTC?
// NOLINTNEXTLINE (fuchsia-statically-constructed-objects)
struct SetupSSL {
    SetupSSL() { rtc::InitializeSSL(); }
    ~SetupSSL() { rtc::CleanupSSL(); }
} setup_;

struct Logger :
    public rtc::LogSink
{
    Logger() {
        rtc::LogMessage::AddLogToStream(this, rtc::LS_INFO);
    }

    void OnLogMessage(const std::string &message) override {
        Log() << message << std::endl;
    }
} logger_;


Peer::Peer(S<Origin> origin, Configuration configuration) :
    origin_(std::move(origin)),
    peer_([&]() {
        const auto &threads(Threads::Get());

        auto factory(webrtc::CreateModularPeerConnectionFactory([&]() {
            webrtc::PeerConnectionFactoryDependencies dependencies;
            dependencies.network_thread = &origin_->Thread();
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


void Peer::OnSignalingChange(webrtc::PeerConnectionInterface::SignalingState state) noexcept {
    orc_trace();
}

void Peer::OnRenegotiationNeeded() noexcept {
    orc_trace();
}

void Peer::OnIceConnectionChange(webrtc::PeerConnectionInterface::IceConnectionState state) noexcept {
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
            closed_();
        break;

        case webrtc::PeerConnectionInterface::kIceConnectionMax:
        default:
            orc_insist(false);
        break;
    }
}

void Peer::OnStandardizedIceConnectionChange(webrtc::PeerConnectionInterface::IceConnectionState state) noexcept {
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
            Spawn([self = shared_from_this()]() mutable noexcept -> task<void> {
                co_await Post([self = std::move(self)]() {
                    for (auto current(self->channels_.begin()); current != self->channels_.end(); ) {
                        auto next(current);
                        ++next;
                        (*current)->Stop("kIceConnectionClosed");
                        current = next;
                    }

                    self->Stop();
                });
            }, __FUNCTION__);
        break;

        case webrtc::PeerConnectionInterface::kIceConnectionClosed:
            if (Verbose)
                Log() << "OnStandardizedIceConnectionChange(kIceConnectionClosed)" << std::endl;
            // this is (annoyingly) only signaled via OnIceConnectionChange
            orc_insist(false);
        break;

        case webrtc::PeerConnectionInterface::kIceConnectionMax:
        default:
            orc_insist(false);
        break;
    }
}

void Peer::OnIceGatheringChange(webrtc::PeerConnectionInterface::IceGatheringState state) noexcept {
    switch (state) {
        case webrtc::PeerConnectionInterface::kIceGatheringNew:
            gathering_.clear();
        break;

        case webrtc::PeerConnectionInterface::kIceGatheringGathering:
        break;

        case webrtc::PeerConnectionInterface::kIceGatheringComplete:
            orc_except({ candidates_ = gathering_; })
            gathered_();
        break;
    }
}

void Peer::OnIceCandidate(const webrtc::IceCandidateInterface *candidate) noexcept {
    std::string sdp;
    candidate->ToString(&sdp);
    gathering_.push_back(sdp);
}

void Peer::OnDataChannel(rtc::scoped_refptr<webrtc::DataChannelInterface> interface) noexcept {
    Land(std::move(interface));
}


rtc::scoped_refptr<rtc::RTCCertificate> Certify() {
    return rtc::RTCCertificate::Create(rtc::OpenSSLIdentity::CreateWithExpiration(
        "WebRTC", rtc::KeyParams(rtc::KT_DEFAULT), 60*60*24
    ));
}

}
