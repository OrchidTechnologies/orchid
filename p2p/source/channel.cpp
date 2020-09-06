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

#include "channel.hpp"
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

task<std::string> Description(const S<Origin> &origin, std::vector<std::string> ice) {
    Configuration configuration;
    configuration.ice_ = std::move(ice);
    const auto client(Make<Actor>(origin, std::move(configuration)));
    const auto stopper(Break<BufferSink<Stopper>>());
    stopper->Wire<Channel>(client);
    co_return co_await client->Offer();
}

}
