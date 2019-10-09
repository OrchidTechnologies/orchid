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


#include <cppcoro/async_latch.hpp>

#include <openvpn/addr/ipv4.hpp>

#include <dns.h>

#include "acceptor.hpp"
#include "capture.hpp"
#include "client.hpp"
#include "connection.hpp"
#include "database.hpp"
#include "directory.hpp"
#include "forge.hpp"
#include "monitor.hpp"
#include "opening.hpp"
#include "origin.hpp"
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
        auto application(std::get<0>(Statement<One<int32_t>>(*this, R"(pragma application_id)")()));
        orc_assert(application == 0);

        Statement<Skip>(*this, R"(pragma journal_mode = wal)")();
        Statement<Skip>(*this, R"(pragma secure_delete = on)")();
        Statement<None>(*this, R"(pragma synchronous = full)")();

        Statement<None>(*this, R"(begin)")();

        auto version(std::get<0>(Statement<One<int32_t>>(*this, R"(pragma user_version)")()));
        switch (version) {
            case 0:
                Statement<None>(*this, R"(
                    create table "flow" (
                        "id" integer primary key autoincrement,
                        "start" real,
                        "layer4" integer,
                        "src_addr" integer,
                        "src_port" integer,
                        "dst_addr" integer,
                        "dst_port" integer,
                        "protocol" string,
                        "hostname" text
                    )
                )")();
            case 1:
                break;
            default:
                orc_assert(false);
        }

        Statement<None>(*this, R"(pragma user_version = 1)")();
        Statement<None>(*this, R"(commit)")();
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
    Statement<Last, uint8_t, uint32_t, uint16_t, uint32_t, uint16_t> insert_;
    Statement<None, std::string_view, sqlite3_int64> update_hostname_;
    Statement<None, std::string_view, sqlite3_int64> update_protocol_;
    DnsLog dns_log_;
    std::map<Five, sqlite3_int64> flow_to_row_;
    std::map<Five, std::string> flow_to_protocol_chain_;

  public:
    Logger(const std::string &path) :
        database_(path),
        insert_(database_, R"(
            insert into "flow" (
                "start", "layer4", "src_addr", "src_port", "dst_addr", "dst_port"
            ) values (
                julianday('now'), ?, ?, ?, ?, ?
            )
        )"),
        update_hostname_(database_, R"(
            update "flow" set
                "hostname" = ?
            where
                "id" = ?
        )"),
        update_protocol_(database_, R"(
            update "flow" set
                "protocol" = ?
            where
                "id" = ?
        )")
    {
    }

    void Analyze(Span<const uint8_t> span) override {
        monitor(span, *this);
    }

    void get_DNS_answers(const Span<const uint8_t> &span) {
        dns_decoded_t decoded[DNS_DECODEBUF_4K];
        size_t decodesize = sizeof(decoded);

        // From the author:
        // And while passing in a char * declared buffer to dns_decode() may appear to
        // work, it only works on *YOUR* system; it may not work on other systems.
        dns_rcode rc = dns_decode(decoded, &decodesize, reinterpret_cast<const dns_packet_t *>(span.data()), span.size());

        if (rc != RCODE_OKAY) {
            return;
        }

        dns_query_t *result = reinterpret_cast<dns_query_t *>(decoded);
        std::string hostname = "";
        for (size_t i = 0; i != result->qdcount; ++i) {
            hostname = result->questions[i].name;
            hostname.pop_back();
            break;
        }
        if (!hostname.empty()) {
            for (size_t i = 0; i != result->ancount; ++i) {
                // TODO: IPv6
                if (result->answers[i].generic.type == RR_A) {
                    auto ip = asio::ip::address_v4(boost::endian::native_to_big(result->answers[i].a.address));
                    Log() << "DNS " << hostname << " " << ip << std::endl;
                    dns_log_[ip] = hostname;
                    break;
                }
            }
        }
    }

    void AnalyzeIncoming(Span<const uint8_t> span) override {
        auto &ip4(span.cast<const openvpn::IPv4Header>());
        if (ip4.protocol == openvpn::IPCommon::UDP) {
            auto length(openvpn::IPv4Header::length(ip4.version_len));
            auto &udp(span.cast<const openvpn::UDPHeader>(length));
            if (boost::endian::native_to_big(udp.source) == 53)
                get_DNS_answers(span + (length + sizeof(openvpn::UDPHeader)));
        }
    }

    void AddFlow(Five const &five) override {
        auto flow(flow_to_row_.find(five));
        if (flow != flow_to_row_.end())
            return;
        const auto &source(five.Source());
        const auto &target(five.Target());
        // XXX: IPv6
        auto row_id = insert_(five.Protocol(),
            source.Host().to_v4().to_uint(), source.Port(),
            target.Host().to_v4().to_uint(), target.Port()
        );
        flow_to_row_.emplace(five, row_id);

        auto hostname(dns_log_.find(target.Host()));
        if (hostname != dns_log_.end()) {
            update_hostname_(hostname->second, row_id);
        }
    }

    void GotHostname(Five const &five, const std::string_view hostname) override {
        auto flow_row(flow_to_row_.find(five));
        if (flow_row == flow_to_row_.end()) {
            orc_assert(false);
            return;
        }
        update_hostname_(hostname, flow_row->second);
    }

    void GotProtocol(Five const &five, const std::string_view protocol, const std::string_view protocol_chain) override {
        auto flow_row(flow_to_row_.find(five));
        if (flow_row == flow_to_row_.end()) {
            orc_assert(false);
            return;
        }
        auto flow_protocol_chain(flow_to_protocol_chain_.find(five));
        if (flow_protocol_chain != flow_to_protocol_chain_.end()) {
            auto s = flow_protocol_chain->second;
            size_t specificity = std::count(protocol_chain.begin(), protocol_chain.end(), ':');
            size_t current_specificity = std::count(s.begin(), s.end(), ':');
            if (specificity < current_specificity) {
                return;
            }
        }
        flow_to_protocol_chain_[five] = protocol_chain;
        update_protocol_(protocol, flow_row->second);
    }
};

void Capture::Land(const Buffer &data) {
    //Log() << "\e[35;1mSEND " << data.size() << " " << data << "\e[0m" << std::endl;
    if (internal_) Spawn([this, data = Beam(data)]() mutable -> task<void> {
        co_return co_await internal_->Send(std::move(data));
    });
}

void Capture::Stop(const std::string &error) {
    orc_insist(false);
}

void Capture::Drop(Beam data) {
    //Log() << "\e[33;1mRECV " << data.size() << " " << data << "\e[0m" << std::endl;
    Spawn([this, data = std::move(data)]() -> task<void> {
        co_return co_await Inner()->Send(data);
    });
}

Capture::Capture(const std::string &local) :
    local_(openvpn::IPv4::Addr::from_string(local).to_uint32())
{
}

Capture::~Capture() = default;


class Punch :
    public BufferSewer
{
  private:
    Hole *const hole_;
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
        header.udp.check = 0;

        header.udp.check = boost::endian::native_to_big(openvpn::udp_checksum(
            reinterpret_cast<uint8_t *>(&header.udp),
            boost::endian::big_to_native(header.udp.len),
            reinterpret_cast<uint8_t *>(&header.ip4.saddr),
            reinterpret_cast<uint8_t *>(&header.ip4.daddr)
        ));

        hole_->Drop(std::move(beam));
    }

    void Stop(const std::string &error) override {
        orc_insist(false);
    }

  public:
    Punch(Hole *hole, Socket socket) :
        hole_(hole),
        socket_(std::move(socket))
    {
    }

    virtual ~Punch() = default;

    task<void> Send(const Buffer &data, const Socket &socket) {
        co_return co_await Inner()->Send(data, socket);
    }
};

struct Ephemeral {
    Socket socket_;
    std::string error_;
    cppcoro::async_manual_reset_event ready_;

    Ephemeral(Socket socket) :
        socket_(std::move(socket))
    {
    }
};

class Plant {
  public:
    virtual task<void> Pull(const Four &four) = 0;
};

class Flow {
  public:
    Plant *plant_;
    Four four_;
    cppcoro::async_latch latch_;
    U<Stream> up_;
    U<Stream> down_;

  private:
    void Splice(Stream *input, Stream *output) {
        Spawn([input, output, &latch = latch_]() -> task<void> {
            Beam beam(2048);
            for (;;) {
                size_t writ;
                try {
                    writ = co_await input->Read(beam);
                } catch (const Error &error) {
                    break;
                }

                if (writ == 0)
                    break;

                try {
                    co_await output->Send(beam.subset(0, writ));
                } catch (const Error &error) {
                    break;
                }
            }

            co_await output->Shut();
            latch.count_down();
        });
    }

  public:
    Flow(Plant *plant, Four four) :
        plant_(plant),
        four_(std::move(four)),
        latch_(2)
    {
    }

    void Start() {
        Spawn([this]() -> task<void> {
            co_await latch_;
            up_->Close();
            down_->Close();
            co_await plant_->Pull(four_);
        });

        Splice(up_.get(), down_.get());
        Splice(down_.get(), up_.get());
    }
};

class Split :
    public Acceptor,
    public Plant,
    public Internal,
    public Hole
{
  private:
    Hole *const hole_;
    S<Origin> origin_;
    U<Analyzer> analyzer_;

    Socket local_;
    asio::ip::address_v4 remote_;

    cppcoro::async_mutex meta_;
    std::map<Four, S<Ephemeral>> ephemerals_;
    uint16_t ephemeral_ = 0;
    std::map<Socket, S<Flow>> flows_;

    std::map<Socket, U<Punch>> udp_;

  protected:
    void Land(asio::ip::tcp::socket connection, Socket socket) override {
        Spawn([this, connection = std::move(connection), socket = std::move(socket)]() mutable -> task<void> {
            auto flow(co_await [&]() -> task<S<Flow>> {
                auto lock(co_await meta_.scoped_lock_async());
                auto flow(flows_.find(socket));
                if (flow == flows_.end())
                    co_return nullptr;
                co_return flow->second;
            }());
            if (flow == nullptr)
                co_return;
            flow->down_ = std::make_unique<Connection<asio::ip::tcp::socket>>(std::move(connection));
            flow->Start();
        });
    }

    void Stop(const std::string &error) override {
        orc_insist(false);
    }

  public:
    Split(Hole *hole, S<Origin> origin) :
        hole_(hole),
        origin_(std::move(origin)),
        analyzer_(std::make_unique<Logger>(Group() + "/analysis.db"))
    {
    }

    void Connect(uint32_t local);

    void Drop(Beam data) override;
    task<void> Send(Beam data) override;

    task<void> Pull(const Four &four) override {
        auto lock(co_await meta_.scoped_lock_async());
        auto ephemeral(ephemerals_.find(four));
        orc_insist(ephemeral != ephemerals_.end());
        auto flow(flows_.find(ephemeral->second->socket_));
        orc_insist(flow != flows_.end());
        ephemerals_.erase(ephemeral);
        flows_.erase(flow);
_trace();
    }

    // https://www.snellman.net/blog/archive/2016-02-01-tcp-rst/
    // https://superuser.com/questions/1056492/rst-sequence-number-and-window-size/1075512
    void Reset(const Socket &source, const Socket &target, uint32_t sequence, uint32_t acknowledge) {
        struct Header {
            openvpn::IPv4Header ip4;
            openvpn::TCPHeader tcp;
        } orc_packed;

        Beam beam(sizeof(Header));
        auto span(beam.span());
        auto &header(span.cast<Header>());

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
        header.tcp.ack_seq = boost::endian::native_to_big(acknowledge);
        header.tcp.doff_res = sizeof(header.tcp) << 2;
        header.tcp.flags = 4 | 16; // XXX: RST | ACK
        header.tcp.window = 0;
        header.tcp.check = 0;
        header.tcp.urgent_p = 0;

        header.tcp.check = openvpn::udp_checksum(
            reinterpret_cast<uint8_t *>(&header.tcp),
            sizeof(header.tcp),
            reinterpret_cast<uint8_t *>(&header.ip4.saddr),
            reinterpret_cast<uint8_t *>(&header.ip4.daddr)
        );

        openvpn::tcp_adjust_checksum(openvpn::IPCommon::UDP - openvpn::IPCommon::TCP, header.tcp.check);
        header.tcp.check = boost::endian::native_to_big(header.tcp.check);

        Drop(std::move(beam));
    }
};

void Split::Connect(uint32_t local) {
    Acceptor::Connect({asio::ip::address_v4(local), 0});
    local_ = Local();
    // XXX: this is sickening
    remote_ = asio::ip::address_v4(local_.Host().to_v4().to_uint() + 1);
}

void Split::Drop(Beam data) {
    analyzer_->AnalyzeIncoming(data.span());
    return hole_->Drop(std::move(data));
}

task<void> Split::Send(Beam data) {
    auto span(data.span());
    auto &ip4(span.cast<openvpn::IPv4Header>());
    auto length(openvpn::IPv4Header::length(ip4.version_len));

    switch (ip4.protocol) {
        case openvpn::IPCommon::TCP: {
            if (Verbose)
                Log() << "TCP:" << data << std::endl;
            auto &tcp(span.cast<openvpn::TCPHeader>(length));

            Four four(
                {boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(tcp.source)},
                {boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(tcp.dest)}
            );

            bool analyze(false);

            if (four.Source() == local_) {
                auto lock(co_await meta_.scoped_lock_async());
                auto flow(flows_.find(four.Target()));
                if (flow == flows_.end())
                    break;
                orc_insist(flow->second != nullptr);
                const auto &original(flow->second->four_);
                Forge(span, tcp, original.Target(), original.Source());
                analyze = true;
            } else if ((tcp.flags & openvpn::TCPHeader::FLAG_SYN) == 0) {
                analyzer_->Analyze(span);
                auto lock(co_await meta_.scoped_lock_async());
                auto ephemeral(ephemerals_.find(four));
                if (ephemeral == ephemerals_.end())
                    break;
                Forge(span, tcp, ephemeral->second->socket_, local_);
            } else {
                auto ephemeral(co_await [&]() -> task<S<Ephemeral>> {
                    auto lock(co_await meta_.scoped_lock_async());
                    auto &ephemeral(ephemerals_[four]);
                    if (ephemeral == nullptr) {
                        // XXX: this only supports 65k sockets
                        Socket socket(remote_, ++ephemeral_);
                        auto &flow(flows_[socket]);
                        orc_insist(flow == nullptr);
                        flow = Make<Flow>(this, four);
                        ephemeral = Make<Ephemeral>(std::move(socket));
                        Spawn([this, ephemeral, flow, target = four.Target()]() -> task<void> {
                            try {
                                co_await origin_->Connect(flow->up_, target.Host().to_string(), std::to_string(target.Port()));
                            } catch (const std::exception &error) {
                                ephemeral->error_ = error.what();
                                orc_insist(!ephemeral->error_.empty());
                                Log() << ephemeral->error_ << std::endl;
                            }
                            ephemeral->ready_.set();
                        });
                    }
                    co_return ephemeral;
                }());

                co_await ephemeral->ready_;
                analyzer_->Analyze(span);

                if (!ephemeral->error_.empty()) {
                    Reset(four.Target(), four.Source(), 0, boost::endian::big_to_native(tcp.seq) + 1);
                    break;
                }

                Forge(span, tcp, ephemeral->socket_, local_);
            }

            if (Verbose)
                Log() << "OUT " << data << std::endl;
            hole_->Drop(std::move(data));

            if (analyze)
                analyzer_->AnalyzeIncoming(span);
        } break;

        case openvpn::IPCommon::UDP: {
            auto &udp(span.cast<openvpn::UDPHeader>(length));

            Socket source(boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(udp.source));
            auto &punch(udp_[source]);
            if (punch == nullptr) {
                auto sink(std::make_unique<Sink<Punch, Opening, BufferSewer>>(this, source));
                co_await origin_->Open(sink.get());
                punch = std::move(sink);
            }

            uint16_t offset(length + sizeof(openvpn::UDPHeader));
            uint16_t size(boost::endian::big_to_native(udp.len) - sizeof(openvpn::UDPHeader));
            Socket target(boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(udp.dest));
            try {
                co_await punch->Send(data.subset(offset, size), target);
            } catch (...) {
                // XXX: this is a hack. test on Travis' device
                Log() << "FAIL TO SEND UDP from " << source << " to " << target << std::endl;
            }
            analyzer_->Analyze(span);
        } break;

        case openvpn::IPCommon::ICMPv4: {
            analyzer_->Analyze(span);
            if (Verbose)
                Log() << "ICMP" << data << std::endl;
        } break;
    }
}

task<void> Capture::Start(S<Origin> origin) {
    auto split(std::make_unique<Split>(this, std::move(origin)));
    split->Connect(local_);
    internal_ = std::move(split);
    co_return;
}


class Pass :
    public BufferDrain,
    public Internal
{
  private:
    Hole *const hole_;
    U<Analyzer> analyzer_;

  protected:
    virtual Pump *Inner() = 0;

    void Land(const Buffer &data) override {
        Beam beam(data);
        analyzer_->AnalyzeIncoming(beam.span());
        return hole_->Drop(std::move(beam));
    }

    void Stop(const std::string &error) override {
    }

  public:
    Pass(Hole *hole) :
        hole_(hole),
        analyzer_(std::make_unique<Logger>(Group() + "/analysis.db"))
    {
    }

    task<void> Send(Beam beam) override {
        analyzer_->Analyze(beam.span());
        co_return co_await Inner()->Send(beam);
    }
};

task<void> Capture::Start(const std::string &rpc, std::string ovpnfile, std::string username, std::string password) {
    auto origin(co_await Setup(rpc));
    auto pass(std::make_unique<Sink<Pass>>(this));
    co_await Connect(pass.get(), std::move(origin), local_, std::move(ovpnfile), std::move(username), std::move(password));
    internal_ = std::move(pass);
}

}
