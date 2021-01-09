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


#ifndef ORCHID_CHANNEL_HPP
#define ORCHID_CHANNEL_HPP

#include <functional>

#include <api/data_channel_interface.h>

#include "configuration.hpp"
#include "link.hpp"
#include "trace.hpp"

namespace orc {

class Origin;
class Peer;
class Socket;

class Channel :
    public Pump<Buffer>,
    public webrtc::DataChannelObserver
{
  private:
    const S<Peer> peer_;
    const rtc::scoped_refptr<webrtc::DataChannelInterface> channel_;

    Event opened_;

  public:
    Channel(BufferDrain &drain, const S<Peer> &peer, const rtc::scoped_refptr<webrtc::DataChannelInterface> &channel);
    Channel(BufferDrain &drain, const S<Peer> &peer, int id = -1, const std::string &label = std::string(), const std::string &protocol = std::string());

    static task<Socket> Wire(BufferSunk &sunk, S<Origin> origin, Configuration configuration, const std::function<task<std::string> (std::string)> &respond);

    ~Channel() override;

    void OnStateChange() noexcept override;
    void OnBufferedAmountChange(uint64_t previous) noexcept override;
    void OnMessage(const webrtc::DataBuffer &buffer) noexcept override;

    void Stop(const std::string &error = std::string()) noexcept;

    task<void> Open() noexcept;
    task<void> Shut() noexcept override;

    task<void> Send(const Buffer &data) override;
};

task<std::string> Description(const S<Origin> &origin, std::vector<std::string> ice);

}

#endif//ORCHID_CHANNEL_HPP
