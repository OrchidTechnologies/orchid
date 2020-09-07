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

#include <pc/sctp_data_channel.h>

#include "channel.hpp"
#include "pirate.hpp"
#include "tube.hpp"

namespace orc {

class Actor final :
    public Peer
{
  protected:
    void Land(rtc::scoped_refptr<webrtc::DataChannelInterface> interface) override {
        orc_assert(false);
    }

    void Stop(const std::string &error) noexcept override {
        // XXX: how much does this matter?
orc_trace();
    }

  public:
    Actor(S<Origin> origin, Configuration configuration) :
        Peer(std::move(origin), std::move(configuration))
    {
    }

    ~Actor() override {
        Close();
    }
};

task<Socket> Channel::Wire(BufferSunk &sunk, S<Origin> origin, Configuration configuration, const std::function<task<std::string> (std::string)> &respond) {
    const auto client(Make<Actor>(std::move(origin), std::move(configuration)));
    auto &channel(sunk.Wire<Channel>(client));
    const auto answer(co_await respond(Strip(co_await client->Offer())));
    co_await client->Negotiate(answer);
    co_await channel.Open();
    const auto candidate(co_await client->Candidate());
    const auto &socket(candidate.address());
    co_return Socket(socket.ipaddr().ipv4_address(), socket.port());
}

Channel::Channel(BufferDrain &drain, const S<Peer> &peer, const rtc::scoped_refptr<webrtc::DataChannelInterface> &channel) :
    Pump<Buffer>(typeid(*this).name(), drain),
    peer_(peer),
    channel_(channel)
{
    channel_->RegisterObserver(this);
    peer_->channels_.insert(this);
}

Channel::Channel(BufferDrain &drain, const S<Peer> &peer, int id, const std::string &label, const std::string &protocol) :
    Channel(drain, peer, [&]() {
        webrtc::DataChannelInit init;
        init.ordered = false;
        init.protocol = protocol;
        if (id != -1) {
            init.negotiated = true;
            init.id = id;
        }
        return (*peer)->CreateDataChannel(label, &init);
    }())
{
}

Channel::~Channel() {
    peer_->channels_.erase(this);
    channel_->UnregisterObserver();
}

void Channel::OnStateChange() noexcept {
    switch (channel_->state()) {
        case webrtc::DataChannelInterface::kConnecting:
            if (Verbose)
                Log() << "OnStateChange(kConnecting)" << std::endl;
            break;
        case webrtc::DataChannelInterface::kOpen:
            if (Verbose)
                Log() << "OnStateChange(kOpen)" << std::endl;
            opened_();
            break;
        case webrtc::DataChannelInterface::kClosing:
            if (Verbose)
                Log() << "OnStateChange(kClosing)" << std::endl;
            break;
        case webrtc::DataChannelInterface::kClosed:
            if (Verbose)
                Log() << "OnStateChange(kClosed)" << std::endl;
            Stop();
            break;
    }
}

void Channel::OnBufferedAmountChange(uint64_t previous) noexcept {
    //auto current(channel_->buffered_amount());
    //Log() << "channel: " << current << " (" << previous << ")" << std::endl;
}

void Channel::OnMessage(const webrtc::DataBuffer &buffer) noexcept {
    const Strung data(buffer.data);
    Trace("WebRTC", false, false, data);
    Pump::Land(data);
}

void Channel::Stop(const std::string &error) noexcept {
    opened_();
    return Pump::Stop(error);
}

task<void> Channel::Open() noexcept {
    co_await *opened_;
}

task<void> Channel::Shut() noexcept {
    channel_->Close();
    // XXX: this should be checking if Peer has a data_transport
    if (channel_->id() == -1)
        Stop();
    co_await Pump::Shut();
}

struct Buffered_ { typedef uint64_t (webrtc::SctpDataChannel::*type); };
template struct Pirate<Buffered_, &webrtc::SctpDataChannel::buffered_amount_>;

struct Send_ { typedef bool (webrtc::SctpDataChannel::*type)(const webrtc::DataBuffer &, bool); };
template struct Pirate<Send_, &webrtc::SctpDataChannel::SendDataMessage>;

task<void> Channel::Send(const Buffer &data) {
    Trace("WebRTC", true, false, data);

    const auto size(data.size());
    rtc::CopyOnWriteBuffer buffer(size);
    data.copy(buffer.data(), size);

    co_await Post([&]() {
#if 0
        if (channel_->buffered_amount() == 0)
            channel_->Send({buffer, true});
#else
        const auto sctp(reinterpret_cast<webrtc::SctpDataChannel *const *>(channel_.get() + 1)[1]);
#if 0
        sctp->Send({buffer, true});
#else
        if (sctp->state() != webrtc::DataChannelInterface::kOpen)
            return;
        sctp->*Loot<Buffered_>::pointer += size;
        if (!(sctp->*Loot<Send_>::pointer)({buffer, true}, false))
            sctp->*Loot<Buffered_>::pointer -= size;
#endif
#endif
    }, RTC_FROM_HERE);
}

task<std::string> Description(const S<Origin> &origin, std::vector<std::string> ice) {
    Configuration configuration;
    configuration.ice_ = std::move(ice);
    const auto client(Make<Actor>(origin, std::move(configuration)));
    const auto stopper(Break<BufferSink<Stopper>>());
    stopper->Wire<Channel>(client);
    co_return co_await client->Offer();
}

}
