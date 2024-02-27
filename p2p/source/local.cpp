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


#include <p2p/base/basic_packet_socket_factory.h>
#include <rtc_base/thread.h>

#include "connection.hpp"
#include "local.hpp"
#include "manager.hpp"
#include "port.hpp"
#include "spawn.hpp"

namespace orc {

class LocalOpening :
    public Opening
{
  private:
    asio::ip::udp::socket connection_;

  public:
    template <typename... Args_>
    LocalOpening(BufferSewer &drain, Args_ &&...args) :
        Opening(typeid(*this).name(), drain),
        connection_(Context(), std::forward<Args_>(args)...)
    {
    }

    asio::ip::udp::socket *operator ->() {
        return &connection_;
    }

    Socket Local() const override {
        return connection_.local_endpoint();
    }

    void Open() {
        Spawn([this]() noexcept -> task<void> {
            for (;;) {
                // XXX: use Beam.subset
                char data[2048];
                asio::ip::udp::endpoint endpoint;
                size_t writ;
                try {
                    writ = co_await connection_.async_receive_from(asio::buffer(data), endpoint, Adapt());
                } catch (const asio::system_error &error) {
                    orc_ignore({ orc_adapt(error); });
                    continue;
                }

                const Subset subset(data, writ);
                if (Verbose)
                    Log() << "\e[33mRECV " << writ << " " << subset << "\e[0m" << std::endl;
                drain_.Land(subset, endpoint);
            }

            Stop();
        }, __FUNCTION__);
    }

    void Open(const Socket &endpoint) {
        connection_.open(asio::ip::udp::v4());
        connection_.non_blocking(true);
        connection_.bind(endpoint);
        Open();
    }

    task<void> Shut() noexcept override {
        orc_except({ connection_.close(); })
        co_await Opening::Shut();
    }

    task<void> Send(const Buffer &data, const Socket &socket) override {
        const auto writ(co_await connection_.async_send_to(Window(data), {socket.Host(), socket.Port()}, Adapt()));
        orc_assert_(writ == data.size(), "orc_assert(" << writ << " {writ} == " << data.size() << " {data.size()})");
    }
};

Local::Local(U<rtc::NetworkManager> manager) :
    Base(typeid(*this).name(), std::move(manager))
{
}

Local::Local(const class Host &host) :
    Local(std::make_unique<Assistant>(host))
{
}

Local::Local() :
    Local(std::make_unique<Manager>(Thread_().socketserver()))
{
}

class Host Local::Host() {
    // XXX: get local address
    return Host_;
}

rtc::Thread &Local::Thread_() {
    static const std::unique_ptr<rtc::Thread> thread([&]() {
        auto thread(rtc::Thread::CreateWithSocketServer());
        thread->SetName("orchid:local", nullptr);
        thread->Start();
        return thread;
    }());

    return *thread;
}

rtc::Thread &Local::Thread() {
    return Thread_();
}

rtc::BasicPacketSocketFactory &Local::Factory() {
    static rtc::BasicPacketSocketFactory factory(Thread().socketserver());
    return factory;
}

task<void> Local::Associate(BufferSunk &sunk, const Socket &endpoint) {
    auto association(std::make_unique<Association<asio::ip::udp::socket>>(Context()));
    co_await association->Open(endpoint);
    auto &inverted(sunk.Wire<Inverted>(std::move(association)));
    inverted.Open();
}

task<Socket> Local::Unlid(Sunk<BufferSewer, Opening> &sunk) {
    auto &opening(sunk.Wire<LocalOpening>());
    opening.Open({asio::ip::address_v4::any(), 0});
    co_return opening.Local();
}

task<U<Stream>> Local::Connect(const Socket &endpoint) {
    auto connection(std::make_unique<Connection>(Context()));
    co_await connection->Open(endpoint);
    co_return connection;
}

}
