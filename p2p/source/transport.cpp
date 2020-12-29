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


#define OPENVPN_EXTERN extern
#include <ovpncli.hpp>

#include <asio.hpp>
#define OPENVPN_LOG_CLASS openvpn::ClientAPI::LogReceiver
#define OPENVPN_LOG_INFO openvpn::ClientAPI::LogInfo
#include <openvpn/log/logthread.hpp>

#include <openvpn/init/initprocess.hpp>

#include <openvpn/transport/client/extern/config.hpp>

#include <openvpn/tun/client/tunbase.hpp>
#include <openvpn/tun/extern/config.hpp>

#include <boost/asio/executor_work_guard.hpp>

#include "dns.hpp"
#include "error.hpp"
#include "event.hpp"
#include "forge.hpp"
#include "nest.hpp"
#include "transport.hpp"

namespace orc {

void Initialize() {
    // XXX: leak this on purpose as this API is annoying
    new openvpn::InitProcess::Init();
    // NOLINTNEXTLINE (clang-analyzer-cplusplus.NewDeleteLeaks)
}

class Transport :
    public openvpn::TransportClient,
    public Covered<Valve>,
    public BufferDrain,
    public Sunken<Pump<Buffer>>
{
  private:
    const S<Origin> origin_;
    const openvpn::ExternalTransport::Config config_;

    openvpn_io::io_context &context_;
    openvpn::TransportClientParent *parent_;

    asio::executor_work_guard<openvpn_io::io_context::executor_type> work_;

    Event ready_;
    Nest nest_;

  protected:
    void Land(const Buffer &data) override {
        static size_t payload(65536);
        const auto size(data.size());
        orc_assert_(size <= payload, "orc_assert(Land: " << size << " {data.size()} <= " << payload << ") " << data);
        //Log() << "\e[33mRECV " << data.size() << " " << data << "\e[0m" << std::endl;
        openvpn::BufferAllocated buffer(payload, openvpn::BufferAllocated::ARRAY);
        buffer.set_size(size);
        data.copy(buffer.data(), buffer.size());
        asio::dispatch(context_, [this, buffer = std::move(buffer)]() mutable {
            //std::cerr << Subset(buffer.data(), buffer.size()) << std::endl;
            if (parent_ == nullptr)
                return;
            parent_->transport_recv(buffer);
        });
    }

    void Stop(const std::string &error) noexcept override {
        if (parent_ == nullptr)
            return;
        parent_->transport_error(openvpn::Error::RELAY_ERROR, error);
        Valve::Stop();
    }

  public:
    Transport(S<Origin> origin, openvpn::ExternalTransport::Config config, openvpn_io::io_context &context, openvpn::TransportClientParent *parent) :
        Covered(typeid(*this).name()),
        origin_(std::move(origin)),
        config_(std::move(config)),
        context_(context),
        parent_(parent),
        work_(context_.get_executor())
    {
    }

    void Open(BufferSunk &sunk) {
        // XXX: use something more specialized than Event
        Spawn([this, &sunk]() noexcept -> task<void> { try {
            asio::dispatch(context_, [this]() {
                if (parent_ == nullptr)
                    return;
                parent_->transport_pre_resolve();
                parent_->transport_wait();
            });

            orc_assert(config_.remote_list);
            const auto remote(config_.remote_list->first_item());
            orc_assert(remote != nullptr);

            const auto endpoints(co_await origin_->Resolve(remote->server_host, remote->server_port));
            for (const auto &endpoint : endpoints) {
                co_await origin_->Associate(sunk, endpoint);
                break;
            }

            asio::dispatch(context_, [this]() noexcept {
                if (parent_ == nullptr)
                    return;
                parent_->transport_connecting();
            });
        } catch (const std::exception &error) {
            asio::dispatch(context_, [this, what = std::string(error.what())]() noexcept {
                if (parent_ == nullptr)
                    return;
                parent_->transport_error(openvpn::Error::RELAY_ERROR, what);
            });
        } ready_(); }, __FUNCTION__);
    }

    task<void> Shut() noexcept override {
        co_await nest_.Shut();
        co_await *ready_;
        co_await Sunken::Shut();
        co_await Valve::Shut();
    }

    void transport_start() noexcept override {
        // this function should not even exist in this API :/
        // it is always called immediately after construction
    }

    void stop() noexcept override {
        parent_ = nullptr;
        Valve::Stop();
        Wait(Shut());
        work_.reset();
    }

    bool transport_send_const(const openvpn::Buffer &data) noexcept override {
        nest_.Hatch([&]() noexcept { return [this, buffer = Beam(data.c_data(), data.size())]() -> task<void> {
            //Log() << "\e[35mSEND " << buffer.size() << " " << buffer << "\e[0m" << std::endl;
            co_await Inner().Send(buffer);
        // XXX: like half of clang-tidy, this lint doesn't work! :/
        // NOLINTNEXTLINE (clang-analyzer-cplusplus.NewDeleteLeaks)
        }; }, __FUNCTION__);

        return true;
    }

    bool transport_send(openvpn::BufferAllocated &buffer) noexcept override {
        nest_.Hatch([&]() noexcept { return [this, buffer = std::move(buffer)]() -> task<void> {
            Subset data(buffer.c_data(), buffer.size());
            //Log() << "\e[35mSEND " << data.size() << " " << data << "\e[0m" << std::endl;
            co_await Inner().Send(data);
        }; }, __FUNCTION__);

        return true;
    }

    bool transport_send_queue_empty() noexcept override {
        return false; }
    bool transport_has_send_queue() noexcept override {
        return false; }
    unsigned int transport_send_queue_size() noexcept override {
        return 0; }

    // no one calls this. it has something to do with UWP
    // c0de92c7e43fbf7ed71622b9de8695651bafacb7 OVPN3-124
    void transport_stop_requeueing() noexcept override {}

    void reset_align_adjust(const size_t adjust) noexcept override {
        // XXX: this has something to do with frames?
    }

    openvpn::IP::Addr server_endpoint_addr() const noexcept override {
        return openvpn::IP::Addr("0.0.0.0"); } // XXX
    void server_endpoint_info(std::string &host, std::string &port, std::string &protocol, std::string &address) const noexcept override {
        host.clear(); port.clear(); protocol.clear(); address.clear(); }
    openvpn::Protocol transport_protocol() const noexcept override {
        return openvpn::Protocol(openvpn::Protocol::UDPv4); }

    void transport_reparent(openvpn::TransportClientParent *parent) noexcept override {
        orc_insist(parent_ != nullptr);
        parent_ = parent;
    }
};

class Factory :
    public openvpn::TransportClientFactory
{
  private:
    S<Origin> origin_;
    openvpn::ExternalTransport::Config config_;

  public:
    Factory(S<Origin> origin, const openvpn::ExternalTransport::Config &config) :
        origin_(std::move(origin)),
        config_(config)
    {
    }

    openvpn::TransportClient::Ptr new_transport_client_obj(openvpn_io::io_context &context, openvpn::TransportClientParent *parent) noexcept override {
        openvpn::RCPtr transport(new BufferSink<Transport>(origin_, config_, context, parent));
        transport->Open(*transport);
        return transport;
    }
};

// tunnels to the left of me, transports to the right;
// here I am, stuck in the middle with you... - Middle

class Middle :
    public openvpn::ClientAPI::OpenVPNClient,
    public Link<Buffer>
{
  private:
    class Tunnel :
        public openvpn::TunClient
    {
      private:
        Middle &middle_;
        openvpn::ExternalTun::Config config_;
        openvpn_io::io_context &context_;
        openvpn::TunClientParent &parent_;

      public:
        Tunnel(Middle &middle, const openvpn::ExternalTun::Config &config, openvpn_io::io_context &context, openvpn::TunClientParent &parent) :
            middle_(middle),
            config_(config),
            context_(context),
            parent_(parent)
        {
        }

        task<void> Send(openvpn::BufferAllocated buffer) {
            Event done;

            asio::dispatch(context_, [&parent = parent_, buffer = std::move(buffer), &done]() mutable {
                // XXX: maybe I need to transfer exceptions or something
                parent.tun_recv(buffer);
                done();
            });

            co_await *done;
        }


        void tun_start(const openvpn::OptionList &options, openvpn::TransportClient &transport, openvpn::CryptoDCSettings &settings) override {
            parent_.tun_pre_tun_config();
            parent_.tun_pre_route_config();

            openvpn::TunProp::configure_builder(&middle_, nullptr, config_.stats.get(), transport.server_endpoint_addr(), config_.tun_prop, options, nullptr, false);

            parent_.tun_connected();
            middle_.Set(this);
        }

        void stop() noexcept override {
            middle_.Set(nullptr);
        }

        void set_disconnect() noexcept override {
        }


        bool tun_send(openvpn::BufferAllocated &buffer) noexcept override {
            if (orc_ignore({ middle_.Forge(buffer); }))
                return false;
            Subset data(buffer.c_data(), buffer.size());
            middle_.Land(data);
            return true;
        }

        std::string tun_name() const noexcept override {
            return "tun_name()"; }

        std::string vpn_ip4() const noexcept override {
            return "vpn_ip4()"; }
        std::string vpn_ip6() const noexcept override {
            return "vpn_ip6()"; }

        std::string vpn_gw4() const noexcept override {
            return "vpn_gw4()"; }
        std::string vpn_gw6() const noexcept override {
            return "vpn_gw6()"; }
    };

    class Factory :
        public openvpn::TunClientFactory
    {
      private:
        Middle &middle_;
        openvpn::ExternalTun::Config config_;

      public:
        Factory(Middle &middle, const openvpn::ExternalTun::Config &config) :
            middle_(middle),
            config_(config)
        {
        }

        openvpn::TunClient::Ptr new_tun_client_obj(openvpn_io::io_context &context, openvpn::TunClientParent &parent, openvpn::TransportClient *transport) noexcept override {
            return new Tunnel(middle_, config_, context, parent);
        }
    };

  private:
    const S<Origin> origin_;
    const uint32_t local_;

    uint32_t remote_ = 0;
    Tunnel *tunnel_ = nullptr;

    Event ready_;

    void Set(Tunnel *tunnel) {
        tunnel_ = tunnel;
        ready_();
    }

    void Forge(openvpn::BufferAllocated &buffer) {
        Span span(buffer.data(), buffer.size());
        const auto remote(ForgeIP4(span, &openvpn::IPv4Header::daddr, local_));
        orc_assert_(remote == remote_, "packet to " << Host(remote) << " != " << Host(remote_));
    }

  public:
    Middle(BufferDrain &drain, S<Origin> origin, uint32_t local) :
        Link<Buffer>(typeid(*this).name(), drain),
        origin_(std::move(origin)),
        local_(local)
    {
    }

    openvpn::TransportClientFactory *new_transport_factory(const openvpn::ExternalTransport::Config &config) noexcept override {
        return new orc::Factory(origin_, config);
    }

    openvpn::TunClientFactory *new_tun_factory(const openvpn::ExternalTun::Config &config, const openvpn::OptionList &options) noexcept override {
        return new Factory(*this, config);
    }


    void log(const openvpn::ClientAPI::LogInfo &info) noexcept override {
        Log() << "OpenVPN: " << info.text << std::endl;
    }

    void event(const openvpn::ClientAPI::Event &event) noexcept override {
        Log() << "OpenVPN[" << event.name << "]: " << event.info << std::endl;
    }


    bool socket_protect(int socket, std::string remote, bool ipv6) noexcept override {
        // we do this by hooking the internal implementation of bind/connect
        return true;
    }

    bool pause_on_connection_timeout() noexcept override {
        return false;
    }


    void external_pki_cert_request(openvpn::ClientAPI::ExternalPKICertRequest &request) noexcept override {
        request.error = true;
        request.errorText = "not implemented";
    }

    void external_pki_sign_request(openvpn::ClientAPI::ExternalPKISignRequest &request) noexcept override {
        request.error = true;
        request.errorText = "not implemented";
    }


    bool tun_builder_new() noexcept override {
        return true; }
    bool tun_builder_set_session_name(const std::string &name) noexcept override {
        return true; }
    bool tun_builder_set_mtu(int mtu) noexcept override {
        return true; }

    bool tun_builder_set_remote_address(const std::string &address, bool ipv6) noexcept override {
        return true; }

    bool tun_builder_add_address(const std::string &address, int prefix, const std::string &gateway, bool ipv6, bool net30) noexcept override {
        orc_insist(!ipv6);
        remote_ = Host(address).operator uint32_t();
        return true;
    }

    bool tun_builder_reroute_gw(bool ipv4, bool ipv6, unsigned int flags) noexcept override {
        return true; }
    bool tun_builder_add_route(const std::string &address, int prefix, int metric, bool ipv6) noexcept override {
        return true; }
    bool tun_builder_exclude_route(const std::string &address, int prefix, int metric, bool ipv6) noexcept override {
        return true; }

    bool tun_builder_add_dns_server(const std::string &address, bool ipv6) noexcept override {
        return true; }
    bool tun_builder_add_search_domain(const std::string &domain) noexcept override {
        return true; }
    bool tun_builder_add_wins_server(const std::string &wins) noexcept override {
        return true; }

    bool tun_builder_set_proxy_auto_config_url(const std::string &url) noexcept override {
        return true; }
    bool tun_builder_set_proxy_http(const std::string &host, int port) noexcept override {
        return true; }
    bool tun_builder_set_proxy_https(const std::string &host, int port) noexcept override {
        return true; }
    bool tun_builder_add_proxy_bypass(const std::string &proxy) noexcept override {
        return true; }


    task<void> Connect(std::string file, std::string username, std::string password) {
        try {
            openvpn::ClientAPI::Config config;
            config.content = std::move(file);
            const auto eval(eval_config(config));
            orc_assert_(!eval.error, eval.message);

            if (eval.autologin) {
                orc_assert(username.empty());
                orc_assert(password.empty());
            } else {
                openvpn::ClientAPI::ProvideCreds credentials;
                credentials.username = std::move(username);
                credentials.password = std::move(password);
                const auto status(provide_creds(credentials));
                orc_assert_(!status.error, status.status << ": " << status.message);
            }

            std::thread([this]() {
                const auto status(connect());
                ready_();
                if (!status.error)
                    Stop();
                else {
                    std::ostringstream error;
                    error << status.status << " " << status.message;
                    Stop(error.str());
                }
            }).detach();
        } catch (const std::exception &error) {
            co_return Stop(error.what());
        }

        co_await *ready_;
    }

    task<void> Shut() noexcept override {
        stop();
        co_await Link::Shut();
    }

    task<void> Send(const orc::Buffer &data) override {
        static const size_t headroom(512);
        static const size_t payload(65536);
        static const size_t tailroom(512);
        const auto size(data.size());
        orc_assert_(size <= payload, "orc_assert(Send: " << size << " {data.size()} <= " << payload << ") " << data);

        openvpn::BufferAllocated buffer(headroom + payload + tailroom, openvpn::BufferAllocated::ARRAY);
        buffer.reset_offset(headroom);
        buffer.set_size(size);
        data.copy(buffer.data(), buffer.size());

        Span span(buffer.data(), buffer.size());
        const auto local(ForgeIP4(span, &openvpn::IPv4Header::saddr, remote_));
        orc_assert_(local == local_, "packet from " << Host(local) << " != " << Host(local_));

        orc_assert(tunnel_ != nullptr);
        co_await tunnel_->Send(std::move(buffer));
    }
};

task<void> Connect(BufferSunk &sunk, S<Origin> origin, uint32_t local, std::string file, std::string username, std::string password) {
    auto &middle(sunk.Wire<Middle>(std::move(origin), local));
    co_await middle.Connect(std::move(file), std::move(username), std::move(password));
}

}
