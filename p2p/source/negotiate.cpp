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


#include "peer.hpp"

namespace orc {

task<void> Peer::Negotiate(webrtc::SessionDescriptionInterface *description) {
    const rtc::scoped_refptr<SetObserver> observer(new rtc::RefCountedObject<SetObserver>());
    peer_->SetLocalDescription(observer, description);
    co_await observer->Wait();
}

task<std::string> Peer::Negotiation(webrtc::SessionDescriptionInterface *description) {
    co_await Negotiate(description);
    co_await gathered_.Wait();
    std::string sdp;
    peer_->local_description()->ToString(&sdp);
    co_return sdp;
}

task<std::string> Peer::Offer() {
    co_return co_await Negotiation(co_await [&]() -> task<webrtc::SessionDescriptionInterface *> {
        const rtc::scoped_refptr<CreateObserver> observer(new rtc::RefCountedObject<CreateObserver>());
        webrtc::PeerConnectionInterface::RTCOfferAnswerOptions options;
        peer_->CreateOffer(observer, options);
        co_await observer->Wait();
        co_return observer->description_;
    }());
}

task<void> Peer::Negotiate(const char *type, const std::string &sdp) {
    webrtc::SdpParseError error;
    const auto answer(webrtc::CreateSessionDescription(type, sdp, &error));
    orc_assert_(answer != nullptr, "invalid " << type << ":\n" << sdp);
    rtc::scoped_refptr<SetObserver> observer(new rtc::RefCountedObject<SetObserver>());
    peer_->SetRemoteDescription(observer, answer);
    co_await observer->Wait();
}

task<std::string> Peer::Answer(const std::string &offer) {
    co_await Negotiate("offer", offer);
    co_return co_await Negotiation(co_await [&]() -> task<webrtc::SessionDescriptionInterface *> {
        const rtc::scoped_refptr<orc::CreateObserver> observer(new rtc::RefCountedObject<orc::CreateObserver>());
        webrtc::PeerConnectionInterface::RTCOfferAnswerOptions options;
        peer_->CreateAnswer(observer, options);
        co_await observer->Wait();
        co_return observer->description_;
    }());
}

task<void> Peer::Negotiate(const std::string &sdp) {
    co_return co_await Negotiate("answer", sdp);
}

}
