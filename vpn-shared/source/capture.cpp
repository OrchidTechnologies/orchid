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


#include <openvpn/addr/ipv4.hpp>

#include <dns.h>

#include "capture.hpp"
#include "database.hpp"
#include "directory.hpp"
#include "forge.hpp"
#include "monitor.hpp"
#include "syscall.hpp"
#include "transport.hpp"

namespace orc {

Analyzer::~Analyzer() = default;
Internal::~Internal() = default;

class LoggerDatabase :
    public Database
{
  public:
    LoggerDatabase(const std::string &path) :
        Database(path)
    {
        Statement<>(*this, R"(
            create table if not exists "flow" (
                "start" real,
                "protocol" integer,
                "src_addr" integer,
                "src_port" integer,
                "dst_addr" integer,
                "dst_port" integer,
                "hostname" text
            );
        )")();
    }
};

// IP => hostname (most recent)
typedef std::map<asio::ip::address, std::string> DnsLog;

class Logger :
    public Analyzer,
    public MonitorLogger
{
  private:
    LoggerDatabase database_;
    Statement<uint8_t, uint32_t, uint16_t, uint32_t, uint16_t> insert_;
    Statement<std::string, sqlite3_int64> update_;
    DnsLog dns_log_;
    std::map<Five, sqlite3_int64> flows_;

  public:
    Logger(const std::string &path) :
        database_(path),
        insert_(database_, R"(
            insert into flow (
                "start", "protocol", "src_addr", "src_port", "dst_addr", "dst_port"
            ) values (
                julianday('now'), ?, ?, ?, ?, ?
            )
        )"),
        update_(database_, R"(
            update flow set hostname = ? where _rowid_ = ?
        )")
    {
    }

    void Analyze(Span<> span) override {
        monitor(span.data(), span.size(), *this);
    }

    void get_DNS_answers(const uint8_t *data, int end) {
        dns_decoded_t decoded[DNS_DECODEBUF_4K];
        size_t decodesize = sizeof(decoded);

        // From the author:
        // And while passing in a char * declared buffer to dns_decode() may appear to
        // work, it only works on *YOUR* system; it may not work on other systems.
        dns_rcode rc = dns_decode(decoded, &decodesize, (const dns_packet_t *const)data, end);

        if (rc != RCODE_OKAY) {
            return;
        }

        dns_query_t *result = (dns_query_t *)decoded;
        for (size_t i = 0; i < result->ancount; i++) {
            // TODO: IPv6
            if (result->answers[i].generic.type == RR_A) {
                auto ip = asio::ip::address_v4(ntohl(result->answers[i].a.address));
                auto hostname = std::string(result->answers[i].a.name);
                hostname.pop_back();
                Log() << "DNS " << hostname << " " << ip << std::endl;
                dns_log_[ip] = hostname;
            }
        }
    }

    void AnalyzeIncoming(Span<> span) override {
        auto &ip4(span.cast<openvpn::IPv4Header>());
        if (ip4.protocol == openvpn::IPCommon::UDP) {
            auto length(openvpn::IPv4Header::length(ip4.version_len));
            auto &udp(span.cast<openvpn::UDPHeader>(length));
            if (ntohs(udp.source) == 53) {
                auto skip = length + sizeof(openvpn::UDPHeader);
                get_DNS_answers((span.data() + skip), span.size() - skip);
            }
        }
    }

    void AddFlow(Five const &five) override {
        auto flow(flows_.find(five));
        if (flow != flows_.end())
            return;
        const auto &source(five.Source());
        const auto &target(five.Target());
        // XXX: IPv6
        auto row_id = insert_(five.Protocol(),
            source.Host().to_v4().to_uint(), source.Port(),
            target.Host().to_v4().to_uint(), target.Port()
        );
        flows_.emplace(five, row_id);

        auto hostname(dns_log_.find(target.Host()));
        if (hostname != dns_log_.end()) {
            update_(hostname->second, row_id);
        }
    }

    void GotHostname(Five const &five, const std::string &hostname) override {
        auto flow(flows_.find(five));
        if (flow == flows_.end()) {
            orc_assert(false);
            return;
        }
        update_(hostname, flow->second);
    }
};

void Capture::Land(const Buffer &data) {
    //Log() << "\e[35;1mSEND " << data.size() << " " << data << "\e[0m" << std::endl;
    Beam beam(data);
    analyzer_->Analyze(beam.span());
    if (internal_) Spawn([this, beam = std::move(beam)]() mutable -> task<void> {
        co_return co_await internal_->Send(std::move(beam));
    });
}

void Capture::Stop(const std::string &error) {
    orc_insist(false);
}

void Capture::Send(const Buffer &data) {
    //Log() << "\e[33;1mRECV " << data.size() << " " << data << "\e[0m" << std::endl;
    Beam beam(data);
    analyzer_->AnalyzeIncoming(beam.span());
    Spawn([this, beam = std::move(beam)]() -> task<void> {
        co_return co_await Inner()->Send(beam);
    });
}

Capture::Capture(const std::string &local) :
    analyzer_(std::make_unique<Logger>(Group() + "/analysis.db")),
    local_(openvpn::IPv4::Addr::from_string(local).to_uint32())
{
}

Capture::~Capture() = default;


class Flow :
    public BufferDrain
{
  private:
    Sync *const sync_;

  protected:
    virtual Link *Inner() = 0;

    void Land(const Buffer &data) override {
        (void) sync_;
        Log() << "Land" << data << std::endl;
    }

    void Stop(const std::string &error) override {
    }

  public:
    Flow(Sync *sync) :
        sync_(sync)
    {
    }

    virtual ~Flow() = default;

    task<uint16_t> Ephemeral() {
        co_return 0;
    }
};

class Punch :
    public ExtendedDrain
{
  private:
    Sync *const sync_;
    Socket socket_;

    virtual Opening *Inner() = 0;

  protected:
    void Land(const Buffer &data, Socket socket) override {
        struct Header {
            openvpn::IPv4Header ip4;
            openvpn::UDPHeader udp;
        } orc_packed;

        Beam beam(sizeof(Header) + data.size());
        auto span(beam.span());
        auto &header(span.cast<Header>(0));
        span.copy(sizeof(header), data);

        header.ip4.version_len = openvpn::IPv4Header::ver_len(4, sizeof(header.ip4));
        header.ip4.tos = 0;
        header.ip4.tot_len = boost::endian::native_to_big<uint16_t>(span.size());
        header.ip4.id = 0;
        header.ip4.frag_off = 0;
        header.ip4.ttl = 64;
        header.ip4.protocol = openvpn::IPCommon::UDP;
        header.ip4.check = 0;
        header.ip4.saddr = boost::endian::native_to_big(socket.Host().to_v4().to_uint());
        header.ip4.daddr = boost::endian::native_to_big(socket_.Host().to_v4().to_uint());

        header.ip4.check = openvpn::IPChecksum::checksum(span.data(), sizeof(header.ip4));

        header.udp.source = boost::endian::native_to_big(socket.Port());
        header.udp.dest = boost::endian::native_to_big(socket_.Port());
        header.udp.len = boost::endian::native_to_big<uint16_t>(sizeof(openvpn::UDPHeader) + data.size());

        header.udp.check = boost::endian::native_to_big(openvpn::udp_checksum(
            reinterpret_cast<uint8_t *>(&header.udp),
            boost::endian::big_to_native(header.udp.len),
            reinterpret_cast<uint8_t *>(&header.ip4.saddr),
            reinterpret_cast<uint8_t *>(&header.ip4.daddr)
        ));

        sync_->Send(std::move(beam));
    }

  public:
    Punch(Sync *sync, Socket socket) :
        sync_(sync),
        socket_(std::move(socket))
    {
    }

    virtual ~Punch() = default;

    task<void> Send(const Buffer &data, const Socket &socket) {
        co_return co_await Inner()->Send(data, socket);
    }
};

class Split :
    public Internal
{
  private:
    Sync *const sync_;
    S<Origin> origin_;

    Socket local_;
    asio::ip::address_v4 remote_;

    cppcoro::async_mutex meta_;
    std::map<Four, U<Flow>> tcp_;
    std::map<Socket, U<Punch>> udp_;

  public:
    Split(Sync *sync, S<Origin> origin) :
        sync_(sync),
        origin_(std::move(origin))
    {
    }

    void Start();

    task<void> Send(Beam data);

    // https://www.snellman.net/blog/archive/2016-02-01-tcp-rst/
    // https://superuser.com/questions/1056492/rst-sequence-number-and-window-size/1075512
    void Reset(const Socket &source, const Socket &target, uint32_t sequence) {
        struct Header {
            openvpn::IPv4Header ip4;
            openvpn::TCPHeader tcp;
        } orc_packed;

        Beam beam(sizeof(Header));
        auto span(beam.span());
        auto &header(span.cast<Header>(0));

        header.ip4.version_len = openvpn::IPv4Header::ver_len(4, sizeof(header.ip4));
        header.ip4.tos = 0;
        header.ip4.tot_len = boost::endian::native_to_big<uint16_t>(span.size());
        header.ip4.id = 0;
        header.ip4.frag_off = 0;
        header.ip4.ttl = 64;
        header.ip4.protocol = openvpn::IPCommon::TCP;
        header.ip4.check = 0;
        header.ip4.saddr = boost::endian::native_to_big(source.Host().to_v4().to_uint());
        header.ip4.daddr = boost::endian::native_to_big(target.Host().to_v4().to_uint());

        header.ip4.check = openvpn::IPChecksum::checksum(span.data(), sizeof(header.ip4));

        header.tcp.source = boost::endian::native_to_big(source.Port());
        header.tcp.dest = boost::endian::native_to_big(target.Port());
        header.tcp.seq = boost::endian::native_to_big(sequence);
        header.tcp.ack_seq = 0;
        header.tcp.doff_res = sizeof(header.tcp) << 2;
        header.tcp.flags = 4; // XXX: openvpn::TCPHeader::FLAG_RST
        //header.tcp.window = ;
        header.tcp.check = 0;
        header.tcp.urgent_p = 0;

        header.tcp.check = boost::endian::native_to_big(openvpn::udp_checksum(
            reinterpret_cast<uint8_t *>(&header.tcp),
            sizeof(header.tcp),
            reinterpret_cast<uint8_t *>(&header.ip4.saddr),
            reinterpret_cast<uint8_t *>(&header.ip4.daddr)
        ));

        sync_->Send(std::move(beam));
    }
};

void Split::Start() {
}

task<void> Split::Send(Beam beam) {
    auto span(beam.span());
    auto &ip4(span.cast<openvpn::IPv4Header>());
    auto length(openvpn::IPv4Header::length(ip4.version_len));

    switch (ip4.protocol) {
        case openvpn::IPCommon::TCP: {
            Log() << "TCP:" << beam << std::endl;
            auto &tcp(span.cast<openvpn::TCPHeader>(length));

            Four four(
                {boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(tcp.source)},
                {boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(tcp.dest)}
            );

            auto ephemeral(co_await [&]() -> task<uint16_t> {
                auto &flow(co_await [&]() -> task<U<Flow> &> {
                    auto lock(co_await meta_.scoped_lock_async());
                    co_return tcp_[four];
                }());

                if (flow != nullptr)
                    co_return co_await flow->Ephemeral();
                else if ((tcp.flags & openvpn::TCPHeader::FLAG_SYN) == 0)
                    co_return 0;
                else {
                    auto sink(std::make_unique<Sink<Flow>>(sync_));
                    auto &target(four.Target());
                    co_await origin_->Connect(sink.get(), target.Host().to_string(), std::to_string(target.Port()));
                    flow = std::move(sink);
                    co_return 0;
                }
            }());

            /*if (ephemeral == 0)
                Reset();
            else*/ {
                ForgeIP4(span, &openvpn::IPv4Header::saddr, remote_.to_uint());
                Forge(tcp, &openvpn::TCPHeader::source, ephemeral);
                ForgeIP4(span, &openvpn::IPv4Header::daddr, local_.Host().to_v4().to_uint());
                Forge(tcp, &openvpn::TCPHeader::dest, local_.Port());
                sync_->Send(std::move(beam));
            }
        } break;

        case openvpn::IPCommon::UDP: {
            auto &udp(span.cast<openvpn::UDPHeader>(length));

            Socket source(boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(udp.source));
            auto &punch(udp_[source]);
            if (punch == nullptr) {
                auto sink(std::make_unique<Sink<Punch, Opening, ExtendedDrain>>(sync_, source));
                co_await origin_->Open(sink.get());
                punch = std::move(sink);
            }

            uint16_t offset(length + sizeof(openvpn::UDPHeader));
            uint16_t size(boost::endian::big_to_native(udp.len) - sizeof(openvpn::UDPHeader));
            Socket target(boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(udp.dest));
            co_await punch->Send(beam.subset(offset, size), target);
        } break;

        case openvpn::IPCommon::ICMPv4: {
            Log() << "ICMP" << beam << std::endl;
        } break;
    }
}

task<void> Capture::Start(S<Origin> origin) {
    auto split(std::make_unique<Split>(this, std::move(origin)));
    split->Start();
    internal_ = std::move(split);
    co_return;
}


class Pass :
    public BufferDrain,
    public Internal
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
    Pass(Sync *sync) :
        sync_(sync)
    {
    }

    task<void> Send(Beam beam) override {
        co_return co_await Inner()->Send(beam);
    }
};

task<void> Capture::Start(std::string ovpnfile, std::string username, std::string password) {
    auto origin(co_await Setup());
    auto pass(std::make_unique<Sink<Pass>>(this));
    co_await Connect(pass.get(), std::move(origin), local_, std::move(ovpnfile), std::move(username), std::move(password));
    internal_ = std::move(pass);
}

}
