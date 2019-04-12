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


#include "channel.hpp"
#include "trace.hpp"

namespace orc {

static rtc::Thread *thread_;

__attribute__((__constructor__))
static void SetupThread() {
    static std::mutex mutex_;
    static std::condition_variable condition_;

    std::thread thread([]() {
        {
            std::unique_lock<std::mutex> lock(mutex_);
            thread_ = rtc::Thread::Current();
            condition_.notify_one();
        }

        thread_->Run();
    });

    {
        std::unique_lock<std::mutex> lock(mutex_);
        condition_.wait(lock, []() {
            return thread_ != NULL;
        });
    }

    thread.detach();
    _trace();
}

struct SetupSSL {
    SetupSSL() { rtc::InitializeSSL(); }
    ~SetupSSL() { rtc::CleanupSSL(); }
} setup_;

Connection::Connection() :
    peer_([&]() {
        static auto factory(webrtc::CreatePeerConnectionFactory(
            thread_, thread_, thread_,
            nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr
        ));

        webrtc::PeerConnectionInterface::RTCConfiguration configuration;
        return factory->CreatePeerConnection(configuration, nullptr, nullptr, this);
    }())
{
}

void Connection::OnIceConnectionChange(webrtc::PeerConnectionInterface::IceConnectionState state) {
    switch (state) {
        case webrtc::PeerConnectionInterface::kIceConnectionNew:
            break;
        case webrtc::PeerConnectionInterface::kIceConnectionChecking:
            break;
        case webrtc::PeerConnectionInterface::kIceConnectionConnected:
            _trace();
            break;
        case webrtc::PeerConnectionInterface::kIceConnectionCompleted:
            _trace();
            break;
        case webrtc::PeerConnectionInterface::kIceConnectionDisconnected:
            _trace();
            break;
        case webrtc::PeerConnectionInterface::kIceConnectionFailed:
            for (auto current(channels_.begin()); current != channels_.end(); ) {
                auto next(current);
                ++next;
                (*current)->Close();
                current = next;
            }
            _trace();
            break;
        case webrtc::PeerConnectionInterface::kIceConnectionClosed:
            _trace();
            break;
        case webrtc::PeerConnectionInterface::kIceConnectionMax:
            break;
        default:
            break;
    }
}

void Connection::OnDataChannel(rtc::scoped_refptr<webrtc::DataChannelInterface> interface) {
    auto self(shared_from_this());
    auto channel(std::make_unique<Channel>(self, interface));
    self->OnChannel(std::move(channel));
}

}
