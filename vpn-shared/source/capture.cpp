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


#include <openvpn/ip/csum.hpp>
#include <openvpn/ip/ip4.hpp>
#include <openvpn/ip/tcp.hpp>
#include <openvpn/ip/udp.hpp>

#include "capture.hpp"
#include "transport.hpp"

namespace orc {

class Route :
    public BufferDrain,
    public Pipe
{
  private:
    Sync *const sync_;

  protected:
    virtual Link *Inner() = 0;

    void Land(const Buffer &data) override {
        return sync_->Send(data);
    }

    void Stop(const std::string &error) override {
    }

  public:
    Route(Sync *sync) :
        sync_(sync)
    {
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await Inner()->Send(data);
    }
};

void Capture::Land(const Buffer &data) {
    //Log() << "\e[35;1mSEND " << data.size() << " " << data << "\e[0m" << std::endl;
    Beam beam(data);
    Span span(beam.data(), beam.size());

    // analyze/monitor data

    auto &ip4(span.cast<openvpn::IPv4Header>());
    if (ip4.protocol == openvpn::IPCommon::TCP) {
        auto length(openvpn::IPv4Header::length(ip4.version_len));
        auto &tcp(span.cast<openvpn::TCPHeader>(length));
        if ((tcp.flags & openvpn::TCPHeader::FLAG_SYN) != 0) {
            Log() << "TCP=" << std::hex << boost::endian::big_to_native(ip4.daddr) << ":" << std::dec << boost::endian::big_to_native(tcp.dest) << std::endl;
        }
    }

    if (route_) Spawn([this, beam = std::move(beam)]() -> task<void> {
        co_return co_await route_->Send(beam);
    });
}

void Capture::Stop(const std::string &error) {
    orc_insist(false);
}

void Capture::Send(const Buffer &data) {
    //Log() << "\e[33;1mRECV " << data.size() << " " << data << "\e[0m" << std::endl;

    Spawn([this, data = Beam(data)]() -> task<void> {
        co_return co_await Inner()->Send(data);
    });
}

Capture::Capture() {
}

Capture::~Capture() = default;

task<void> Capture::Start(std::string ovpnfile, std::string username, std::string password) {
    auto origin(co_await Setup());
    auto route(std::make_unique<Sink<Route>>(this));
    co_await Connect(route.get(), std::move(origin), std::move(ovpnfile), std::move(username), std::move(password));
    route_ = std::move(route);
}

}
