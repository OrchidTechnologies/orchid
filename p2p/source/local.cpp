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


#include <p2p/base/basic_packet_socket_factory.h>

#include "connection.hpp"
#include "local.hpp"
#include "manager.hpp"
#include "port.hpp"

namespace orc {

class LocalOpening final :
    public Opening
{
  private:
    asio::ip::udp::socket connection_;

  public:
    template <typename... Args_>
    LocalOpening(BufferSewer *drain, Args_ &&...args) :
        Opening(drain),
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
        Spawn([this]() -> task<void> {
            for (;;) {
                asio::ip::udp::endpoint endpoint;

                char data[2048];
                size_t writ;
                try {
                    writ = co_await connection_.async_receive_from(asio::buffer(data), endpoint, Token());
                } catch (const asio::system_error &error) {
                    orc_adapt(error);
                }

                Subset region(data, writ);
                if (Verbose)
                    Log() << "\e[33mRECV " << writ << " " << region << "\e[0m" << std::endl;
                drain_->Land(region, endpoint);
            }
        });
    }

    void Open(const Socket &socket) {
        connection_.open(asio::ip::udp::v4());
        connection_.non_blocking(true);
        connection_.bind({socket.Host(), socket.Port()});
        Open();
    }

    task<void> Shut() override {
        connection_.close();
        co_return;
    }

    task<void> Send(const Buffer &data, const Socket &socket) override {
        auto writ(co_await connection_.async_send_to(Sequence(data), {socket.Host(), socket.Port()}, Token()));
        orc_assert_(writ == data.size(), "orc_assert(" << writ << " {writ} == " << data.size() << " {data.size()})");
    }
};

Local::Local(U<rtc::NetworkManager> manager) :
    Origin(std::move(manager))
{
}

Local::Local(const class Host &host) :
    Local(std::make_unique<Assistant>(host))
{
}

Local::Local() :
    Local(std::make_unique<Manager>())
{
}

class Host Local::Host() {
    // XXX: get local address
    return Host_;
}

rtc::Thread *Local::Thread() {
    static std::unique_ptr<rtc::Thread> thread;
    if (thread == nullptr) {
        thread = rtc::Thread::CreateWithSocketServer();
        thread->SetName("Orchid WebRTC Local", nullptr);
        thread->Start();
    }

    return thread.get();
}

rtc::BasicPacketSocketFactory &Local::Factory() {
    static rtc::BasicPacketSocketFactory factory(Thread());
    return factory;
}

task<Socket> Local::Associate(Sunk<> *sunk, const std::string &host, const std::string &port) {
    auto connection(std::make_unique<Connection<asio::ip::udp::socket>>(Context()));
    auto endpoint(co_await connection->Open(host, port));
    auto inverted(sunk->Wire<Inverted>(std::move(connection)));
    inverted->Open();
    co_return Socket(endpoint.address(), endpoint.port());
}

task<Socket> Local::Connect(U<Stream> &stream, const std::string &host, const std::string &port) {
    auto connection(std::make_unique<Connection<asio::ip::tcp::socket>>(Context()));
    auto endpoint(co_await connection->Open(host, port));
    stream = std::move(connection);
    co_return Socket(endpoint.address(), endpoint.port());
}

task<Socket> Local::Unlid(Sunk<BufferSewer, Opening> *sunk) {
    auto opening(sunk->Wire<LocalOpening>());
    opening->Open({asio::ip::address_v4::any(), 0});
    co_return opening->Local();
}

}
