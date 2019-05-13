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


#include <boost/regex.hpp>

#include <api/sctp_transport_interface.h>
#include <p2p/base/ice_transport_internal.h>

#include "rtc_base/ssl_adapter.h"

#include "channel.hpp"
#include "trace.hpp"

namespace orc {

static std::unique_ptr<rtc::Thread> signals_;
static std::unique_ptr<rtc::Thread> network_;
static std::unique_ptr<rtc::Thread> working_;

void Post(std::function<void ()> code) {
    signals_->Invoke<void>(RTC_FROM_HERE, std::move(code));
}

__attribute__((__constructor__))
static void SetupThread() {
    signals_ = rtc::Thread::Create();
    signals_->SetName("Orchid WebRTC Signals", nullptr);
    signals_->Start();

    network_ = rtc::Thread::CreateWithSocketServer();
    network_->SetName("Orchid WebRTC Network", nullptr);
    network_->Start();

    working_ = rtc::Thread::Create();
    working_->SetName("Orchid WebRTC Workers", nullptr);
    working_->Start();

    _trace();
}

struct SetupSSL {
    SetupSSL() { rtc::InitializeSSL(); }
    ~SetupSSL() { rtc::CleanupSSL(); }
} setup_;

Connection::Connection(Configuration configuration) :
    peer_([&]() {
        static auto factory(webrtc::CreateModularPeerConnectionFactory([]() {
            webrtc::PeerConnectionFactoryDependencies dependencies;
            dependencies.network_thread = network_.get();
            dependencies.worker_thread = working_.get();
            dependencies.signaling_thread = signals_.get();
            return dependencies;
        }()));

        webrtc::PeerConnectionInterface::RTCConfiguration rtc;

        if (configuration.tls_)
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
            return dependencies;
        }());
    }())
{
}

cricket::Candidate Connection::Candidate() {
    return network_->Invoke<cricket::Candidate>(RTC_FROM_HERE, [&]() -> cricket::Candidate {
        auto sctp(peer_->GetSctpTransport());
        orc_assert(sctp != nullptr);
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

void Connection::OnIceConnectionChange(webrtc::PeerConnectionInterface::IceConnectionState state) {
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

void Connection::OnStandardizedIceConnectionChange(webrtc::PeerConnectionInterface::IceConnectionState state) {
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
            Task([this]() -> task<void> {
                co_return Post([this]() {
                    for (auto current(channels_.begin()); current != channels_.end(); ) {
                        auto next(current);
                        ++next;
                        (*current)->Stop("kIceConnectionClosed");
                        current = next;
                    }

                    Stop();
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

void Connection::OnDataChannel(rtc::scoped_refptr<webrtc::DataChannelInterface> interface) {
    Land(std::move(interface));
}

std::string Strip(std::string sdp) {
    static boost::regex re("\r?\na=candidate:[^\r\n]*");
    return boost::regex_replace(std::move(sdp), re, "");
}

}
