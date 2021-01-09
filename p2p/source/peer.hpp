/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2020  The Orchid Authors
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


#ifndef ORCHID_PEER_HPP
#define ORCHID_PEER_HPP

#include <api/peer_connection_interface.h>

#include "configuration.hpp"
#include "error.hpp"
#include "event.hpp"
#include "link.hpp"
#include "origin.hpp"
#include "threads.hpp"

struct socket;

namespace orc {

class CreateObserver :
    public Event,
    public webrtc::CreateSessionDescriptionObserver
{
  public:
    webrtc::SessionDescriptionInterface *description_;

  protected:
    void OnSuccess(webrtc::SessionDescriptionInterface *description) noexcept override {
        description_ = description;
        operator ()();
    }

    void OnFailure(webrtc::RTCError error) noexcept override {
        orc_insist(false);
    }
};

class SetObserver :
    public Event,
    public webrtc::SetSessionDescriptionObserver
{
  protected:
    void OnSuccess() noexcept override {
        operator ()();
    }

    void OnFailure(webrtc::RTCError error) noexcept override {
        orc_insist(false);
    }
};

class Channel;

class Peer :
    public std::enable_shared_from_this<Peer>,
    public webrtc::PeerConnectionObserver,
    protected Drain<rtc::scoped_refptr<webrtc::DataChannelInterface>>
{
    friend class Channel;

  private:
    const S<Origin> origin_;
    const rtc::scoped_refptr<webrtc::PeerConnectionInterface> peer_;

    // XXX: do I need to lock this?
    std::set<Channel *> channels_;

    Event gathered_;
    std::vector<std::string> gathering_;
    std::vector<std::string> candidates_;

    Event closed_;

  protected:
    void Close() {
        peer_->Close();
    }

  public:
    Peer(S<Origin> origin, Configuration configuration = Configuration());

    ~Peer() override {
        orc_insist(closed_);
    }

    webrtc::PeerConnectionInterface *operator->() {
        return peer_;
    }

    task<struct socket *> Internal();
    task<cricket::Candidate> Candidate();

    void OnSignalingChange(webrtc::PeerConnectionInterface::SignalingState state) noexcept override;
    void OnRenegotiationNeeded() noexcept override;
    void OnIceConnectionChange(webrtc::PeerConnectionInterface::IceConnectionState state) noexcept override;
    void OnStandardizedIceConnectionChange(webrtc::PeerConnectionInterface::IceConnectionState state) noexcept override;
    void OnIceGatheringChange(webrtc::PeerConnectionInterface::IceGatheringState state) noexcept override;
    void OnIceCandidate(const webrtc::IceCandidateInterface *candidate) noexcept override;
    void OnDataChannel(rtc::scoped_refptr<webrtc::DataChannelInterface> interface) noexcept override;

    task<void> Negotiate(webrtc::SessionDescriptionInterface *description);
    task<std::string> Negotiation(webrtc::SessionDescriptionInterface *description);
    task<std::string> Offer();

    task<void> Negotiate(const char *type, const std::string &sdp);
    task<std::string> Answer(const std::string &offer);
    task<void> Negotiate(const std::string &sdp);
};

std::string Strip(const std::string &sdp);

}

#endif//ORCHID_PEER_HPP
