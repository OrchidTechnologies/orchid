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

#include <Foundation/Foundation.h>

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

class OrchidClient :
    public openvpn::TransportClient
{
  private:
    openvpn::ExternalTransport::Config config_;
    asio::io_context &io_context;
    openvpn::TransportClientParent *parent_;

    std::string buffer_;
    orc::U<orc::Sink<>> pipe_;

  public:
    OrchidClient(const openvpn::ExternalTransport::Config config, asio::io_context &io_context, openvpn::TransportClientParent *parent) :
        config_(config),
        io_context(io_context),
        parent_(parent)
    {
    }

    void transport_start() override { cppcoro::sync_wait([this]() -> task<void> {
        co_await orc::Schedule();

        /*NSLog(@"transport_start(): protocol:%s", config_.protocol.protocol_to_string());
        if (config_.frame) for (size_t i(0), e(config_.frame->n_contexts()); i != e; ++i)
            NSLog(@"  frame[%zu]:%s", i, (*config_.frame)[i].info().c_str());
        if (config_.remote_list) NSLog(@"  remote:%s", config_.remote_list->to_string().c_str());*/

        asio::dispatch(io_context, [parent = parent_]() {
            parent->transport_pre_resolve();
            parent->transport_wait();
        });

        _assert(config_.remote_list);
        auto remote(config_.remote_list->first_item());
        _assert(remote != NULL);

        auto link(co_await orc::Setup(remote->server_host, remote->server_port));

        pipe_ = std::make_unique<orc::Sink<>>(std::move(link), [&](const orc::Buffer &data) {
            buffer_ += data.str();
            while (buffer_.size() >= 2) {
                auto size(ntohs(*reinterpret_cast<uint16_t *>(&buffer_[0])));
                if (buffer_.size() < 2 + size)
                    break;
                openvpn::BufferAllocated buffer(reinterpret_cast<const uint8_t *>(buffer_.data() + 2), size, 0);
                buffer_ = buffer_.substr(2 + size);
                asio::dispatch(io_context, [parent = parent_, buffer]() mutable {
                    parent->transport_recv(buffer);
                });
            }
        });

        asio::dispatch(io_context, [parent = parent_]() {
            parent->transport_connecting();
        });
    }()); }

    void stop() override {
        cppcoro::sync_wait([this]() -> task<void> {
            co_await orc::Schedule();
            co_await pipe_->Send(orc::Nothing());
            pipe_.reset();
        }());
    }

    bool transport_send_const(const openvpn::Buffer &data) override {
        std::string packet;
        packet.resize(data.size() + 2);
        memcpy(&packet[2], data.c_data(), data.size());
        *reinterpret_cast<uint16_t *>(&packet[0]) = htons(data.size());
        cppcoro::sync_wait([this, packet = std::move(packet)]() -> task<void> {
            co_await orc::Schedule();
            co_await pipe_->Send(orc::Beam(packet));
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
        return openvpn::Protocol(openvpn::Protocol::TCPv4);
    }

    void transport_reparent(openvpn::TransportClientParent *parent) override {
        parent_ = parent;
    }
};

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
        return new OrchidClient(config_, io_context, parent);
    }
};

namespace orc {
openvpn::TransportClientFactory *NewTransportFactory(const openvpn::ExternalTransport::Config &config) {
    return new OrchidFactory(config);
} }
