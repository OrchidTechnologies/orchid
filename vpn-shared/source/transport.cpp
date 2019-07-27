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

#include <openvpn/ip/csum.hpp>
#include <openvpn/ip/ip4.hpp>
#include <openvpn/ip/tcp.hpp>
#include <openvpn/ip/udp.hpp>

#include <openvpn/transport/client/extern/config.hpp>

#include <openvpn/tun/client/tunbase.hpp>
#include <openvpn/tun/extern/config.hpp>

#include <boost/asio/executor_work_guard.hpp>

#include "client.hpp"
#include "error.hpp"
#include "protect.hpp"
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
    virtual Link *Inner() = 0;

    void Land(const Buffer &data) override {
        //Log() << "\e[33mRECV " << data.size() << " " << data << "\e[0m" << std::endl;
        openvpn::BufferAllocated buffer(data.size(), openvpn::BufferAllocated::ARRAY);
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

            co_await origin_->Connect(transport.get(), remote->server_host, remote->server_port);

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

class Hole :
    public Drain<openvpn::BufferAllocated &>
{
  public:
    virtual void Start(const openvpn::OptionList &options, openvpn::TransportClient &transport, openvpn::CryptoDCSettings &settings) = 0;
};

class Tunnel :
    public openvpn::TunClient
{
  private:
    Hole *hole_;

  public:
    Tunnel(Hole *hole) :
        hole_(hole)
    {
    }

    void tun_start(const openvpn::OptionList &options, openvpn::TransportClient &transport, openvpn::CryptoDCSettings &settings) override {
        hole_->Start(options, transport, settings);
    }

    void stop() override {
        hole_->Stop();
    }

    void set_disconnect() override {
        orc_assert(false);
    }

    bool tun_send(openvpn::BufferAllocated &buffer) override {
        hole_->Land(buffer);
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

static uint32_t Forge4(openvpn::BufferAllocated &buffer, uint32_t (openvpn::IPv4Header::*field), uint32_t value) {
    Span data(buffer.data(), buffer.size());
    auto &ip4(data.cast<openvpn::IPv4Header>());

    auto before(boost::endian::big_to_native(ip4.*field));
    auto adjust((int32_t(before >> 16) + int32_t(before & 0xffff)) - (int32_t(value >> 16) + int32_t(value & 0xffff)));

    ip4.*field = boost::endian::native_to_big(value);
    boost::endian::big_to_native_inplace(ip4.check);
    openvpn::tcp_adjust_checksum(adjust, ip4.check);
    boost::endian::native_to_big_inplace(ip4.check);

    auto length(openvpn::IPv4Header::length(ip4.version_len));
    orc_assert(data.size() >= length);

#if 0
    auto check(ip4.check);
    ip4.check = 0;
    orc_insist(openvpn::IPChecksum::checksum(data.data(), length) == check);
    ip4.check = check;
#endif

    switch (ip4.protocol) {
        case openvpn::IPCommon::TCP: {
            auto &tcp(data.cast<openvpn::TCPHeader>(length));
            boost::endian::big_to_native_inplace(tcp.check);
            openvpn::tcp_adjust_checksum(adjust, tcp.check);
            boost::endian::native_to_big_inplace(tcp.check);
        } break;

        case openvpn::IPCommon::UDP: {
            auto &udp(data.cast<openvpn::UDPHeader>(length));
            boost::endian::big_to_native_inplace(udp.check);
            openvpn::tcp_adjust_checksum(adjust, udp.check);
            boost::endian::native_to_big_inplace(udp.check);
        } break;
    }

    return before;
}

// tunnels to the left of me, transports to the right;
// here I am, stuck in the middle with you... - Client

class Client :
    public openvpn::ClientAPI::OpenVPNClient,
    public openvpn::TunClientFactory,
    public Hole,
    public Sync
{
  private:
    Sync *const sync_;
    S<Origin> origin_;

    std::thread thread_;

    openvpn::ExternalTun::Config config_;
    openvpn::TunClientParent *parent_ = nullptr;
    cppcoro::async_manual_reset_event ready_;

    openvpn::IPv4::Addr ip4_;
    uint32_t local_;

  protected:
    void Start(const openvpn::OptionList &options, openvpn::TransportClient &transport, openvpn::CryptoDCSettings &settings) override {
        parent_->tun_pre_tun_config();
        parent_->tun_pre_route_config();

        openvpn::TunProp::configure_builder(this, nullptr, config_.stats.get(), transport.server_endpoint_addr(), config_.tun_prop, options, nullptr, false);

        parent_->tun_connected();
    }

    void Land(openvpn::BufferAllocated &buffer) override {
        Forge4(buffer, &openvpn::IPv4Header::daddr, local_);
        Subset data(buffer.c_data(), buffer.size());
        //std::cerr << data << std::endl;
        sync_->Send(data);
    }

    void Stop(const std::string &error) override {
        orc_assert_(false, error);
    }

  public:
    Client(Sync *sync, S<Origin> origin) :
        sync_(sync),
        origin_(std::move(origin))
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


    bool tun_builder_add_address(const std::string &address, int prefix, const std::string &gateway, bool ipv6, bool net30) override {
        orc_insist(!ipv6);
        ip4_ = openvpn::IPv4::Addr::from_string(address);
        return true;
    }

    bool tun_builder_add_dns_server(const std::string &address, bool ipv6) override {
        return true; }
    bool tun_builder_reroute_gw(bool ipv4, bool ipv6, unsigned int flags) override {
        return true; }
    bool tun_builder_set_mtu(int mtu) override {
        return true; }
    bool tun_builder_set_remote_address(const std::string &address, bool ipv6) override {
        return true; }
    bool tun_builder_set_session_name(const std::string &name) override {
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

    void Send(const orc::Buffer &data) override {
        if (parent_ == nullptr)
            return;
        static size_t headroom(512);
        openvpn::BufferAllocated buffer(data.size() + headroom, openvpn::BufferAllocated::ARRAY);
        buffer.reset_offset(headroom);
        data.copy(buffer.data(), buffer.size());

        local_ = Forge4(buffer, &openvpn::IPv4Header::saddr, ip4_.to_uint32());

        //std::cerr << Subset(buffer.data(), buffer.size()) << std::endl;
        parent_->tun_recv(buffer);
    }
};

task<U<Sync>> Connect(Sync *sync, S<Origin> origin, std::string ovpnfile, std::string username, std::string password) {
    auto client(std::make_unique<Client>(sync, std::move(origin)));

    {
        openvpn::ClientAPI::Config config;
        config.content = std::move(ovpnfile);
        config.disableClientCert = true;
        client->eval_config(config);
    }

    {
        openvpn::ClientAPI::ProvideCreds credentials;
        credentials.username = std::move(username);
        credentials.password = std::move(password);
        client->provide_creds(credentials);
    }

    co_await client->Connect();
    co_return std::move(client);
}

void Capture::Land(const Buffer &data) {
    //Log() << "\e[35;1mSEND " << data.size() << " " << data << "\e[0m" << std::endl;

    // analyze/monitor data

    if (sync_)
        sync_->Send(data);
}

void Capture::Stop(const std::string &error) {
    orc_insist(false);
}

void Capture::Send(const Buffer &data) {
    //Log() << "\e[33;1mRECV " << data.size() << " " << data << "\e[0m" << std::endl;
    Spawn([this, beam = Beam(data)]() -> task<void> {
        co_await Inner()->Send(beam);
    });
}

Capture::Capture() {
}

Capture::~Capture() = default;

task<void> Capture::Start(std::string ovpnfile, std::string username, std::string password) {
    auto origin(co_await Setup());
    sync_ = co_await Connect(this, std::move(origin), std::move(ovpnfile), std::move(username), std::move(password));
}

}
