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


#include <regex>

#include <pc/data_channel_controller.h>
#include <pc/sctp_data_channel.h>

#include "channel.hpp"
#include "peer.hpp"
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
    Actor(S<Base> base, Configuration configuration) :
        Peer(std::move(base), std::move(configuration))
    {
    }

    ~Actor() override {
        Close();
    }
};

Channel::Channel(BufferDrain &drain, const S<Peer> &peer, rtc::scoped_refptr<webrtc::DataChannelInterface> channel) :
    Pump(typeid(*this).name(), drain),
    peer_(peer),
    channel_(std::move(channel))
{
    channel_->RegisterObserver(this);
}

Channel::Channel(BufferDrain &drain, const S<Peer> &peer, int id, const std::string &label, const std::string &protocol) :
    Channel(drain, peer, [&]() {
        webrtc::DataChannelInit init;
        init.ordered = false;
        init.maxRetransmits = 0;
        init.protocol = protocol;
        if (id != -1) {
            init.negotiated = true;
            init.id = id;
        }
        return (*peer)->CreateDataChannel(label, &init);
    }())
{
}

task<void> Channel::Wire(BufferSunk &sunk, S<Base> base, Configuration configuration, const std::function<task<std::string> (std::string)> &respond) {
    const auto client(co_await Post([&]() { return Make<Actor>(std::move(base), std::move(configuration)); }));
    auto &channel(*co_await Post([&]() { return &sunk.Wire<Channel>(client); }));
    const auto answer(co_await respond(Strip(co_await client->Offer())));
    co_await client->Negotiate(answer);
    co_await channel.Open();
}

void Channel::OnStateChange() noexcept {
    const auto state(channel_->state());
    if (Verbose)
        Log() << this << "->OnStateChange(" << webrtc::DataChannelInterface::DataStateString(state) << ")" << std::endl;
    switch (channel_->state()) {
        case webrtc::DataChannelInterface::kConnecting:
            break;
        case webrtc::DataChannelInterface::kOpen:
            opened_();
            break;
        case webrtc::DataChannelInterface::kClosing:
            break;
        case webrtc::DataChannelInterface::kClosed:
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
    co_await Post([&]() {
        channel_->Close();
    });

    co_await Pump::Shut();

    co_await Post([&]() {
        channel_->UnregisterObserver();
        channel_ = nullptr;
        peer_ = nullptr;
    });
}

template <typename Type_, Type_ Pointer_>
struct P {
    constexpr Type_ value() {
        return Pointer_;
    }
};

struct SctpDataChannel$network_thread_ { typedef rtc::Thread *const (webrtc::SctpDataChannel::*type); };
template struct Pirate<SctpDataChannel$network_thread_, &webrtc::SctpDataChannel::network_thread_>;

task<void> Channel::Send(const Buffer &data) {
    Trace("WebRTC", true, false, data);

    const auto size(data.size());
    rtc::CopyOnWriteBuffer buffer(size);
    data.copy(buffer.MutableData(), size);

    const auto channel(channel_);
    orc_assert(channel != nullptr);
    const auto sctp(static_cast<webrtc::SctpDataChannel *>(reinterpret_cast<void **>(channel.get())[3]));

    Transfer<webrtc::RTCError> writ;

    co_await Post([&]() {
        if (sctp->buffered_amount() != 0)
            writ = webrtc::RTCError();
        else
            sctp->SendAsync({buffer, true}, [&](webrtc::RTCError error) {
                writ = std::move(error); });
    }, *(sctp->*Loot<SctpDataChannel$network_thread_>::pointer));

    const auto error(co_await *writ);
    orc_assert_(error.ok(), error.message());
}

task<std::string> Description(const S<Base> &base, std::vector<std::string> ice) {
    Configuration configuration;
    configuration.ice_ = std::move(ice);
    const auto client(co_await Post([&]() { return Make<Actor>(base, std::move(configuration)); }));
    const auto flap(Break<BufferSink<Flap>>());
    co_await Post([&]() { flap->Wire<Channel>(client); });
    co_return co_await client->Offer();
}

}
