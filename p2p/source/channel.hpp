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


#ifndef ORCHID_CHANNEL_HPP
#define ORCHID_CHANNEL_HPP

#include <functional>

#include "peer.hpp"

namespace orc {

class Socket;

class Channel final :
    public Pump<Buffer>,
    public webrtc::DataChannelObserver
{
  private:
    const S<Peer> peer_;
    const rtc::scoped_refptr<webrtc::DataChannelInterface> channel_;

    Event opened_;

  public:
    static task<Socket> Wire(BufferSunk &sunk, const S<Origin> &origin, Configuration configuration, const std::function<task<std::string> (std::string)> &respond);

    Channel(BufferDrain &drain, const S<Peer> &peer, const rtc::scoped_refptr<webrtc::DataChannelInterface> &channel) :
        Pump<Buffer>(drain),
        peer_(peer),
        channel_(channel)
    {
        type_ = typeid(*this).name();
        channel_->RegisterObserver(this);
        peer_->channels_.insert(this);
    }

    Channel(BufferDrain &drain, const S<Peer> &peer, int id = -1, const std::string &label = std::string(), const std::string &protocol = std::string()) :
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

    ~Channel() override {
_trace();
        peer_->channels_.erase(this);
        channel_->UnregisterObserver();
    }

    S<Peer> Peer() {
        return peer_;
    }

    void OnStateChange() noexcept override {
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

    void OnBufferedAmountChange(uint64_t previous) noexcept override {
        //auto current(channel_->buffered_amount());
        //Log() << "channel: " << current << " (" << previous << ")" << std::endl;
    }

    void OnMessage(const webrtc::DataBuffer &buffer) noexcept override {
        const Subset data(buffer.data.data(), buffer.data.size());
        if (Verbose)
            Log() << "WebRTC >>> " << this << " " << data << std::endl;
        Pump::Land(data);
    }

    void Stop(const std::string &error = std::string()) noexcept {
        opened_();
        return Pump::Stop(error);
    }

    task<void> Open() noexcept {
        co_await opened_.Wait();
    }

    task<void> Shut() noexcept override {
        channel_->Close();
        // XXX: this should be checking if Peer has a data_transport
        if (channel_->id() == -1)
            Stop();
        co_await Pump::Shut();
    }

    task<void> Send(const Buffer &data) override {
        if (Verbose)
            Log() << "WebRTC <<< " << this << " " << data << std::endl;
        rtc::CopyOnWriteBuffer buffer(data.size());
        data.copy(buffer.data(), buffer.size());
        co_await Post([&]() {
            if (channel_->buffered_amount() == 0)
                channel_->Send(webrtc::DataBuffer(buffer, true));
        });
    }
};

task<std::string> Description(const S<Origin> &origin, std::vector<std::string> ice);

}

#endif//ORCHID_CHANNEL_HPP
