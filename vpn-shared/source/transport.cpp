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


#define OPENVPN_EXTERN extern

#include <ovpncli.hpp>

#include "client.hpp"
#include "error.hpp"
#include "link.hpp"
#include "trace.hpp"
#include "transport.hpp"

#define OPENVPN_LOG_CLASS openvpn::ClientAPI::LogReceiver
#define OPENVPN_LOG_INFO openvpn::ClientAPI::LogInfo
#include <openvpn/log/logthread.hpp>

#include <openvpn/common/bigmutex.hpp>

#include <openvpn/transport/client/extern/config.hpp>

#include <cppcoro/sync_wait.hpp>

namespace orc {

class Middle :
    public Link
{
  protected:
    virtual Link *Inner() = 0;

  public:
    using Link::Link;

    task<void> Send(const Buffer &data) override {
        co_return co_await Inner()->Send(data);
    }
};

class Transport :
    public openvpn::TransportClient,
    public orc::BufferDrain
{
  private:
    openvpn::ExternalTransport::Config config_;
    asio::io_context &io_context;
    openvpn::TransportClientParent *parent_;

    U<Pipe> pipe_;

  public:
    // NOLINTNEXTLINE (performance-unnecessary-value-param)
    Transport(const openvpn::ExternalTransport::Config config, asio::io_context &io_context, openvpn::TransportClientParent *parent) :
        config_(config),
        io_context(io_context),
        parent_(parent)
    {
    }


    void Land(const Buffer &data) override {
        //Log() << "\e[33mRECV " << data.size() << " " << data << "\e[0m" << std::endl;
        openvpn::BufferAllocated buffer(data.size(), openvpn::BufferAllocated::ARRAY);
        data.copy(buffer.data(), buffer.size());
        asio::dispatch(io_context, [parent = parent_, buffer = std::move(buffer)]() mutable {
            parent->transport_recv(buffer);
        });
    }

    void Stop(const std::string &error) override {
        std::terminate();
    }


    void transport_start() override { Wait([this]() -> task<void> {
        co_await Schedule();

        asio::dispatch(io_context, [parent = parent_]() {
            parent->transport_pre_resolve();
            parent->transport_wait();
        });

        orc_assert(config_.remote_list);
        auto remote(config_.remote_list->first_item());
        orc_assert(remote != nullptr);

        auto middle(std::make_unique<Sink<Middle>>(this));

        auto origin(co_await Setup());
        co_await origin->Connect(middle.get(), remote->server_host, remote->server_port);

        pipe_ = std::move(middle);

        asio::dispatch(io_context, [parent = parent_]() {
            parent->transport_connecting();
        });
    }()); }

    void stop() override {
        Wait([this]() -> task<void> {
            co_await Schedule();
            co_await pipe_->Send(Nothing());
            pipe_.reset();
        }());
    }

    bool transport_send_const(const openvpn::Buffer &data) override {
        Wait([&]() -> task<void> {
            co_await Schedule();
            Subset buffer(data.c_data(), data.size());
            //Log() << "\e[35mSEND " << data.size() << " " << buffer << "\e[0m" << std::endl;
            co_await pipe_->Send(buffer);
        }());
        return true;
    }

    bool transport_send(openvpn::BufferAllocated &data) override {
        return transport_send_const(data);
    }

    bool transport_send_queue_empty() override {
        return false;
    }

    bool transport_has_send_queue() override {
        return false;
    }

    void transport_stop_requeueing() override {
    }

    unsigned int transport_send_queue_size() override {
        return 0;
    }

    void reset_align_adjust(const size_t adjust) override {
    }

    openvpn::IP::Addr server_endpoint_addr() const override {
        return openvpn::IP::Addr("127.0.0.1");
    }

    void server_endpoint_info(std::string &host, std::string &port, std::string &proto, std::string &ip_addr) const override {
    }

    openvpn::Protocol transport_protocol() const override {
        return openvpn::Protocol(openvpn::Protocol::UDPv4);
    }

    void transport_reparent(openvpn::TransportClientParent *parent) override {
        parent_ = parent;
    }
};

}

class OrchidFactory :
    public openvpn::TransportClientFactory
{
  private:
    openvpn::ExternalTransport::Config config_;

  public:
    OrchidFactory(const openvpn::ExternalTransport::Config &config) :
        config_(config)
    {
    }

    openvpn::TransportClient::Ptr new_transport_client_obj(asio::io_context &io_context, openvpn::TransportClientParent *parent) override {
        return new orc::Transport(config_, io_context, parent);
    }
};

namespace orc {
openvpn::TransportClientFactory *NewTransportFactory(const openvpn::ExternalTransport::Config &config) {
    return new OrchidFactory(config);
} }
