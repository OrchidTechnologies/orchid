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

#include <asio.hpp>
#define OPENVPN_LOG_CLASS openvpn::ClientAPI::LogReceiver
#define OPENVPN_LOG_INFO openvpn::ClientAPI::LogInfo
#include <openvpn/log/logthread.hpp>

#include <openvpn/transport/client/extern/config.hpp>

#include <openvpn/tun/client/tunbase.hpp>
#include <openvpn/tun/extern/config.hpp>

#include <boost/asio/executor_work_guard.hpp>

#include "error.hpp"
#include "forge.hpp"
#include "trace.hpp"
#include "transport.hpp"

namespace orc {

void Initialize() {
    openvpn::ClientAPI::OpenVPNClient::init_process();
}

class Transport :
    public openvpn::TransportClient,
    public BufferDrain
{
  private:
    openvpn_io::io_context &context_;
    openvpn::TransportClientParent *parent_;
    asio::executor_work_guard<openvpn_io::io_context::executor_type> work_;

  protected:
    virtual Pump *Inner() = 0;

    void Land(const Buffer &data) override {
        static size_t payload(65536);
        const auto size(data.size());
        orc_assert_(size <= payload, "orc_assert(Land: " << size << " {data.size()} <= " << payload << ") " << data);
        //Log() << "\e[33mRECV " << data.size() << " " << data << "\e[0m" << std::endl;
        openvpn::BufferAllocated buffer(payload, openvpn::BufferAllocated::ARRAY);
        buffer.set_size(size);
        data.copy(buffer.data(), buffer.size());
        asio::dispatch(context_, [parent = parent_, buffer = std::move(buffer)]() mutable {
            //std::cerr << Subset(buffer.data(), buffer.size()) << std::endl;
            parent->transport_recv(buffer);
        });
    }

    void Stop(const std::string &error) override {
        parent_->transport_error(openvpn::Error::UNDEF, error);
    }

  public:
    Transport(openvpn_io::io_context &context, openvpn::TransportClientParent *parent) :
        context_(context),
        parent_(parent),
        work_(context_.get_executor())
    {
    }

    void transport_start() override {
        // this function should not even exist in this API :/
        // it is always called immediately after construction
    }

    void stop() override {
_trace();
        Wait([&]() -> task<void> {
            co_await Inner()->Shut();
        }());
        work_.reset();
    }

    bool transport_send_const(const openvpn::Buffer &data) override {
        Spawn([this, buffer = Beam(data.c_data(), data.size())]() -> task<void> {
            co_await Schedule();
            //Log() << "\e[35mSEND " << buffer.size() << " " << buffer << "\e[0m" << std::endl;
            co_await Inner()->Send(buffer);
        });

        return true;
    }

    bool transport_send(openvpn::BufferAllocated &buffer) override {
        Spawn([this, buffer = std::move(buffer)]() -> task<void> {
            co_await Schedule();
            Subset data(buffer.c_data(), buffer.size());
            //Log() << "\e[35mSEND " << data.size() << " " << data << "\e[0m" << std::endl;
            co_await Inner()->Send(data);
        });

        return true;
    }

    bool transport_send_queue_empty() override {
        return false; }
    bool transport_has_send_queue() override {
        return false; }
    unsigned int transport_send_queue_size() override {
        return 0; }

    // no one calls this. it has something to do with UWP
    // c0de92c7e43fbf7ed71622b9de8695651bafacb7 OVPN3-124
    void transport_stop_requeueing() override {}

    void reset_align_adjust(const size_t adjust) override {
        // XXX: this has something to do with frames?
    }

    openvpn::IP::Addr server_endpoint_addr() const override {
        return openvpn::IP::Addr("0.0.0.0"); } // XXX
    void server_endpoint_info(std::string &host, std::string &port, std::string &protocol, std::string &address) const override {
        host.clear(); port.clear(); protocol.clear(); address.clear(); }
    openvpn::Protocol transport_protocol() const override {
        return openvpn::Protocol(openvpn::Protocol::UDPv4); }

    void transport_reparent(openvpn::TransportClientParent *parent) override {
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

    openvpn::TransportClient::Ptr new_transport_client_obj(openvpn_io::io_context &context, openvpn::TransportClientParent *parent) override {
        openvpn::RCPtr transport(new Sink<Transport>(context, parent));

        Spawn([this, &context, parent, transport]() -> task<void> { try {
            co_await Schedule();

            asio::dispatch(context, [parent]() {
                parent->transport_pre_resolve();
                parent->transport_wait();
            });

            orc_assert(config_.remote_list);
            auto remote(config_.remote_list->first_item());
            orc_assert(remote != nullptr);

            co_await origin_->Associate(transport.get(), remote->server_host, remote->server_port);

            asio::dispatch(context, [parent]() {
                parent->transport_connecting();
            });
        } catch (const std::exception &error) {
            asio::dispatch(context, [parent, what = error.what()]() {
                parent->transport_error(openvpn::Error::UNDEF, what);
            });
        } });

        return transport;
    }
};

// tunnels to the left of me, transports to the right;
// here I am, stuck in the middle with you... - Middle

class Middle :
    public openvpn::ClientAPI::OpenVPNClient,
    public openvpn::TunClientFactory,
    public Link
{
  private:
    class Tunnel :
        public openvpn::TunClient
    {
      private:
        Middle *middle_;

      public:
        Tunnel(Middle *middle) :
            middle_(middle)
        {
        }

        void tun_start(const openvpn::OptionList &options, openvpn::TransportClient &transport, openvpn::CryptoDCSettings &settings) override {
            middle_->Start(options, transport, settings);
        }

        void stop() override {
            middle_->Stop(std::string());
        }

        void set_disconnect() override {
            orc_assert(false);
        }

        bool tun_send(openvpn::BufferAllocated &buffer) override {
            middle_->Forge(buffer);
            Subset data(buffer.c_data(), buffer.size());
            middle_->Land(data);
            return true;
        }

        std::string tun_name() const override {
            return "tun_name()"; }

        std::string vpn_ip4() const override {
            return "vpn_ip4()"; }
        std::string vpn_ip6() const override {
            return "vpn_ip6()"; }

        std::string vpn_gw4() const override {
            return "vpn_gw4()"; }
        std::string vpn_gw6() const override {
            return "vpn_gw6()"; }
    };

    void Start(const openvpn::OptionList &options, openvpn::TransportClient &transport, openvpn::CryptoDCSettings &settings) {
        parent_->tun_pre_tun_config();
        parent_->tun_pre_route_config();

        openvpn::TunProp::configure_builder(this, nullptr, config_.stats.get(), transport.server_endpoint_addr(), config_.tun_prop, options, nullptr, false);

        parent_->tun_connected();
    }

    void Forge(openvpn::BufferAllocated &buffer) {
        Span span(buffer.data(), buffer.size());
        ForgeIP4(span, &openvpn::IPv4Header::daddr, local_);
    }

  private:
    S<Origin> origin_;

    std::thread thread_;

    openvpn::ExternalTun::Config config_;
    openvpn::TunClientParent *parent_ = nullptr;
    cppcoro::async_manual_reset_event ready_;

    openvpn::IPv4::Addr ip4_;
    uint32_t local_;

  protected:
    virtual Pipe *Inner() = 0;

    void Land(const Buffer &data) override {
        //std::cerr << data << std::endl;
        Link::Land(data);
    }

    void Stop(const std::string &error) override {
        orc_insist(false);
    }

  public:
    Middle(BufferDrain *drain, S<Origin> origin, uint32_t local) :
        Link(drain),
        origin_(std::move(origin)),
        local_(local)
    {
    }

    openvpn::TransportClientFactory *new_transport_factory(const openvpn::ExternalTransport::Config &config) override {
        return new orc::Factory(origin_, config);
    }


    openvpn::TunClientFactory *new_tun_factory(const openvpn::ExternalTun::Config &config, const openvpn::OptionList &options) override {
        config_ = config;
        return this;
    }

    openvpn::TunClient::Ptr new_tun_client_obj(openvpn_io::io_context &context, openvpn::TunClientParent &parent, openvpn::TransportClient *transport) override {
        parent_ = &parent;
        return new Tunnel(this);
    }


    void log(const openvpn::ClientAPI::LogInfo &info) override {
        Log() << "OpenVPN: " << info.text << std::endl;
    }

    void event(const openvpn::ClientAPI::Event &event) override {
        Log() << "OpenVPN[" << event.name << "]: " << event.info << std::endl;
    }


    bool socket_protect(int socket, std::string remote, bool ipv6) override {
        // we do this by hooking the internal implementation of bind/connect
        return true;
    }

    bool pause_on_connection_timeout() override {
        return false;
    }


    void external_pki_cert_request(openvpn::ClientAPI::ExternalPKICertRequest &request) override {
        request.error = true;
        request.errorText = "not implemented";
    }

    void external_pki_sign_request(openvpn::ClientAPI::ExternalPKISignRequest &request) override {
        request.error = true;
        request.errorText = "not implemented";
    }


    bool tun_builder_new() override {
        return true; }
    bool tun_builder_set_session_name(const std::string &name) override {
        return true; }
    bool tun_builder_set_mtu(int mtu) override {
        return true; }

    bool tun_builder_set_remote_address(const std::string &address, bool ipv6) override {
        return true; }

    bool tun_builder_add_address(const std::string &address, int prefix, const std::string &gateway, bool ipv6, bool net30) override {
        orc_insist(!ipv6);
        ip4_ = openvpn::IPv4::Addr::from_string(address);
        return true;
    }

    bool tun_builder_reroute_gw(bool ipv4, bool ipv6, unsigned int flags) override {
        return true; }
    bool tun_builder_add_route(const std::string &address, int prefix, int metric, bool ipv6) override {
        return true; }
    bool tun_builder_exclude_route(const std::string &address, int prefix, int metric, bool ipv6) override {
        return true; }

    bool tun_builder_add_dns_server(const std::string &address, bool ipv6) override {
        return true; }
    bool tun_builder_add_search_domain(const std::string &domain) override {
        return true; }
    bool tun_builder_add_wins_server(const std::string &wins) override {
        return true; }

    bool tun_builder_set_proxy_auto_config_url(const std::string &url) override {
        return true; }
    bool tun_builder_set_proxy_http(const std::string &host, int port) override {
        return true; }
    bool tun_builder_set_proxy_https(const std::string &host, int port) override {
        return true; }
    bool tun_builder_add_proxy_bypass(const std::string &proxy) override {
        return true; }


    task<void> Connect() {
        thread_ = std::thread([this]() {
            auto v = connect();
            Log() << __func__ << " " << __FILE__ << ":" << __LINE__ << " " << v.status << " " << v.message << " " << v.error << std::endl;
_trace();
            orc_insist(false);
        });

        // XXX: put this in the right place
        ready_.set();
        co_await ready_;
    }

    task<void> Send(const orc::Buffer &data) override {
        static size_t headroom(512);
        static size_t payload(65536);
        static size_t tailroom(512);
        const auto size(data.size());
        orc_assert_(size <= payload, "orc_assert(Send: " << size << " {data.size()} <= " << payload << ") " << data);

        openvpn::BufferAllocated buffer(headroom + payload + tailroom, openvpn::BufferAllocated::ARRAY);
        buffer.reset_offset(headroom);
        buffer.set_size(size);
        data.copy(buffer.data(), buffer.size());

        Span span(buffer.data(), buffer.size());
        if (ForgeIP4(span, &openvpn::IPv4Header::saddr, ip4_.to_uint32()) != local_)
            co_return;
        //std::cerr << Subset(buffer.data(), buffer.size()) << std::endl;

        if (parent_ == nullptr)
            co_return;
        parent_->tun_recv(buffer);
    }
};

task<void> Connect(Sunk<> *sunk, S<Origin> origin, uint32_t local, std::string ovpnfile, std::string username, std::string password) {
    auto middle(sunk->Wire<Sink<Middle>>(std::move(origin), local));

    {
        openvpn::ClientAPI::Config config;
        config.content = std::move(ovpnfile);
        middle->eval_config(config);
    }

    {
        openvpn::ClientAPI::ProvideCreds credentials;
        credentials.username = std::move(username);
        credentials.password = std::move(password);
        middle->provide_creds(credentials);
    }

    co_await middle->Connect();
}

}
