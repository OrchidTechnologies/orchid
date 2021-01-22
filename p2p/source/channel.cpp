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
#include <pc/sctp_data_channel_transport.h>

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
    Actor(S<Origin> origin, Configuration configuration) :
        Peer(std::move(origin), std::move(configuration))
    {
    }

    ~Actor() override {
        Close();
    }
};

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

template <typename Type_, Type_ Pointer_>
struct P {
    constexpr Type_ value() {
        return Pointer_;
    }
};

struct SctpDataChannel$buffered_amount_ { typedef uint64_t (webrtc::SctpDataChannel::*type); };
template struct Pirate<SctpDataChannel$buffered_amount_, &webrtc::SctpDataChannel::buffered_amount_>;

struct SctpDataChannel$SendDataMessage { typedef bool (webrtc::SctpDataChannel::*type)(const webrtc::DataBuffer &, bool); };
template struct Pirate<SctpDataChannel$SendDataMessage, &webrtc::SctpDataChannel::SendDataMessage>;

struct SctpDataChannel$provider_ { typedef webrtc::SctpDataChannelProviderInterface *const (webrtc::SctpDataChannel::*type); };
template struct Pirate<SctpDataChannel$provider_, &webrtc::SctpDataChannel::provider_>;

struct DataChannelController$DataChannelSendData { typedef bool (webrtc::DataChannelController::*type)(const cricket::SendDataParams &, const rtc::CopyOnWriteBuffer &, cricket::SendDataResult *); };
template struct Pirate<DataChannelController$DataChannelSendData, &webrtc::DataChannelController::DataChannelSendData>;

struct DataChannelController$network_thread { typedef rtc::Thread *(webrtc::DataChannelController::*type)() const; };
template struct Pirate<DataChannelController$network_thread, &webrtc::DataChannelController::network_thread>;

struct SctpDataChannelTransport$sctp_transport_ { typedef cricket::SctpTransportInternal *const (webrtc::SctpDataChannelTransport::*type); };
template struct Pirate<SctpDataChannelTransport$sctp_transport_, &webrtc::SctpDataChannelTransport::sctp_transport_>;

task<void> Channel::Send(const Buffer &data) {
    Trace("WebRTC", true, false, data);

    const auto size(data.size());
    rtc::CopyOnWriteBuffer buffer(size);
    data.copy(buffer.MutableData(), size);

#if 0
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
#if 0
        sctp->*Loot<SctpDataChannel$buffered_amount_>::pointer += size;
        if (!(sctp->*Loot<SctpDataChannel$SendDataMessage>::pointer)({buffer, true}, false))
            sctp->*Loot<SctpDataChannel$buffered_amount_>::pointer -= size;
#else
        const auto provider(sctp->*Loot<SctpDataChannel$provider_>::pointer);

        cricket::SendDataParams params{
            .sid = sctp->id(),
            .type = cricket::DMT_BINARY,
            .ordered = false,
            .reliable = false,
            .max_rtx_count = 0,
            .max_rtx_ms = -1,
        };

        cricket::SendDataResult result;
#if 0
        provider->SendData(params, buffer, &result);
#else
        // NOLINTNEXTLINE (cppcoreguidelines-pro-type-static-cast-downcast)
        const auto controller(static_cast<webrtc::DataChannelController *>(provider));
        (controller->*Loot<DataChannelController$DataChannelSendData>::pointer)(params, buffer, &result);
#endif
#endif
#endif
#endif
    }, RTC_FROM_HERE);
#else
    const auto sctp(reinterpret_cast<webrtc::SctpDataChannel *const *>(channel_.get() + 1)[1]);
    const auto provider(sctp->*Loot<SctpDataChannel$provider_>::pointer);
    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-static-cast-downcast)
    const auto controller(static_cast<webrtc::DataChannelController *>(provider));

    co_await Post([&]() {
        const auto interface(controller->data_channel_transport());

#if 0
        static const webrtc::SendDataParams params([]() {
            webrtc::SendDataParams params;
            params.type = webrtc::DataMessageType::kBinary;
            params.ordered = false;
            params.max_rtx_count = 0;
            return params;
        }());

        interface->SendData(sctp->id(), params, buffer);
#else
        // NOLINTNEXTLINE (cppcoreguidelines-pro-type-static-cast-downcast)
        const auto transport(static_cast<webrtc::SctpDataChannelTransport *>(interface));

        cricket::SendDataParams params{
            .sid = sctp->id(),
            .type = cricket::DMT_BINARY,
            .ordered = false,
            .reliable = false,
            .max_rtx_count = 0,
            .max_rtx_ms = -1,
        };

        cricket::SendDataResult result;
        (transport->*Loot<SctpDataChannelTransport$sctp_transport_>::pointer)->SendData(params, buffer, &result);
#endif
    }, RTC_FROM_HERE, *(controller->*Loot<DataChannelController$network_thread>::pointer)());
#endif
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
