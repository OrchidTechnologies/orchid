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

#include <boost/filesystem/string_file.hpp>

#include <openvpn/addr/ipv4.hpp>

#include <dns.h>
#include <duktape.h>

#include "acceptor.hpp"
#include "datagram.hpp"
#include "capture.hpp"
#include "client.hpp"
#include "connection.hpp"
#include "database.hpp"
#include "directory.hpp"
#include "forge.hpp"
#include "heap.hpp"
#include "local.hpp"
#include "monitor.hpp"
#include "network.hpp"
#include "origin.hpp"
#include "port.hpp"
#include "remote.hpp"
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
        const auto &destination(five.Target());
        // XXX: IPv6
        auto row_id = insert_(five.Protocol(),
            source.Host(), source.Port(),
            destination.Host(), destination.Port()
        );
        flow_to_row_.emplace(five, row_id);

        auto hostname(dns_log_.find(destination.Host()));
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
    if (internal_) nest_.Hatch([&]() { return [this, data = Beam(data)]() mutable -> task<void> {
        if (co_await internal_->Send(data))
            analyzer_->Analyze(data.span());
    }; });
}

void Capture::Stop(const std::string &error) {
    std::cerr << error << std::endl;
    orc_insist(false);
}

void Capture::Land(const Buffer &data, bool analyze) {
    //Log() << "\e[33;1mRECV " << data.size() << " " << data << "\e[0m" << std::endl;
    Spawn([this, data = Beam(data), analyze]() mutable -> task<void> {
        co_await Inner()->Send(data);
        if (analyze)
            analyzer_->AnalyzeIncoming(data.span());
    });
}

Capture::Capture(const Host &local) :
    local_(local),
    nest_(32),
    analyzer_(std::make_unique<Logger>(Group() + "/analysis.db"))
{
}

Capture::~Capture() = default;


class Hole {
  public:
    virtual ~Hole() = default;

    virtual void Land(const Buffer &data) = 0;
};

class Punch :
    public BufferSewer
{
  private:
    Hole *const hole_;
    Socket socket_;

    virtual Opening *Inner() = 0;

  protected:
    void Land(const Buffer &data, Socket socket) override {
        hole_->Land(Datagram(socket, socket_, data));
    }

    void Stop(const std::string &error) override {
        orc_insist(false);
    }

  public:
    Punch(Hole *hole, Socket socket) :
        hole_(hole),
        socket_(socket)
    {
    }

    virtual ~Punch() = default;

    task<void> Send(const Buffer &data, const Socket &socket) {
        co_return co_await Inner()->Send(data, socket);
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
        four_(four),
        latch_(2)
    {
    }

    void Open() {
        Spawn([this]() -> task<void> {
            co_await latch_;
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
    Capture *const capture_;
    S<Origin> origin_;

    Socket local_;
    asio::ip::address_v4 remote_;

    typedef std::list<Four> LRU_;

    struct Ephemeral_ {
        Socket socket_;
        LRU_::iterator lru_iter_;
    };

    cppcoro::async_mutex meta_;
    std::map<Four, Ephemeral_> ephemerals_;
    std::map<Socket, S<Flow>> flows_;
    std::map<Socket, U<Punch>> udp_;
    LRU_ lru_;

    void RemoveFlow(const Four &four) {
        auto ephemeral(ephemerals_.find(four));
        orc_insist(ephemeral != ephemerals_.end());
        auto flow(flows_.find(ephemeral->second.socket_));
        orc_insist(flow != flows_.end());
        flows_.erase(flow);
    }

    void RemoveEmphemeral(const Four &four) {
        auto ephemeral(ephemerals_.find(four));
        orc_insist(ephemeral != ephemerals_.end());
        flows_.erase(ephemeral->second.socket_);
        lru_.erase(ephemeral->second.lru_iter_);
        ephemerals_.erase(ephemeral);
    }

  protected:
    void Land(asio::ip::tcp::socket connection, Socket socket) override {
        Spawn([this, connection = std::move(connection), socket]() mutable -> task<void> {
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
            flow->Open();
        });
    }

    void Stop(const std::string &error) override {
        orc_insist(false);
    }

  public:
    Split(Capture *capture, S<Origin> origin) :
        capture_(capture),
        origin_(std::move(origin))
    {
    }

    void Connect(const Host &local);

    void Land(const Buffer &data) override;
    task<bool> Send(const Beam &data) override;

    void EphemeralUsed(const Four &four) {
        auto emphemeral_iter(ephemerals_.find(four));
        lru_.erase(emphemeral_iter->second.lru_iter_);
        lru_.push_back(emphemeral_iter->first);
        emphemeral_iter->second.lru_iter_ = std::prev(lru_.end());
    }

    task<void> Pull(const Four &four) override {
        auto lock(co_await meta_.scoped_lock_async());
        RemoveFlow(four);
        _trace();
    }

    // https://www.snellman.net/blog/archive/2016-02-01-tcp-rst/
    // https://superuser.com/questions/1056492/rst-sequence-number-and-window-size/1075512
    void Reset(const Socket &source, const Socket &destination, uint32_t sequence, uint32_t acknowledge) {
        // XXX: rename this to Packet packet (leaving Header for UDP headers)
        struct Header {
            openvpn::IPv4Header ip4;
            openvpn::TCPHeader tcp;
        } orc_packed header;

        header.ip4.version_len = openvpn::IPv4Header::ver_len(4, sizeof(header.ip4));
        header.ip4.tos = 0;
        header.ip4.tot_len = boost::endian::native_to_big<uint16_t>(sizeof(header));
        header.ip4.id = 0;
        header.ip4.frag_off = 0;
        header.ip4.ttl = 64;
        header.ip4.protocol = openvpn::IPCommon::TCP;
        header.ip4.check = 0;
        header.ip4.saddr = boost::endian::native_to_big(source.Host().operator uint32_t());
        header.ip4.daddr = boost::endian::native_to_big(destination.Host().operator uint32_t());

        // NOLINTNEXTLINE (clang-analyzer-core.uninitialized.Assign)
        header.ip4.check = openvpn::IPChecksum::checksum(&header.ip4, sizeof(header.ip4));

        header.tcp.source = boost::endian::native_to_big(source.Port());
        header.tcp.dest = boost::endian::native_to_big(destination.Port());
        header.tcp.seq = boost::endian::native_to_big(sequence);
        header.tcp.ack_seq = boost::endian::native_to_big(acknowledge);
        header.tcp.doff_res = sizeof(header.tcp) << 2;
        header.tcp.flags = 4 | 16; // XXX: RST | ACK
        header.tcp.window = 0;
        header.tcp.check = 0;
        header.tcp.urgent_p = 0;

        // NOLINTNEXTLINE (clang-analyzer-core.UndefinedBinaryOperatorResult)
        header.tcp.check = openvpn::udp_checksum(
            reinterpret_cast<uint8_t *>(&header.tcp),
            sizeof(header.tcp),
            reinterpret_cast<uint8_t *>(&header.ip4.saddr),
            reinterpret_cast<uint8_t *>(&header.ip4.daddr)
        );

        openvpn::tcp_adjust_checksum(openvpn::IPCommon::UDP - openvpn::IPCommon::TCP, header.tcp.check);
        header.tcp.check = boost::endian::native_to_big(header.tcp.check);

        Land(Subset(&header));
    }
};

void Split::Connect(const Host &local) {
    Acceptor::Open({local, 0});
    local_ = Local();
    // XXX: this is sickening
    remote_ = asio::ip::address_v4(local_.Host().operator uint32_t() + 1);
}

void Split::Land(const Buffer &data) {
    return capture_->Land(data, true);
}

task<bool> Split::Send(const Beam &data) {
    Beam beam(data);
    auto span(beam.span());
    Subset subset(span);

    auto &ip4(span.cast<openvpn::IPv4Header>());
    auto length(openvpn::IPv4Header::length(ip4.version_len));

    switch (ip4.protocol) {
        case openvpn::IPCommon::TCP: {
            if (Verbose)
                Log() << "TCP:" << subset << std::endl;
            auto &tcp(span.cast<openvpn::TCPHeader>(length));

            Four four(
                {boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(tcp.source)},
                {boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(tcp.dest)}
            );

            if (four.Source() == local_) {
                auto lock(co_await meta_.scoped_lock_async());
                auto flow(flows_.find(four.Target()));
                if (flow == flows_.end())
                    break;
                orc_insist(flow->second != nullptr);
                const auto &original(flow->second->four_);
                EphemeralUsed(original);
                Forge(span, tcp, original.Target(), original.Source());
                capture_->Land(subset, true);
                co_return false;
            }

            auto lock(co_await meta_.scoped_lock_async());
            auto ephemeral(ephemerals_.find(four));

            if ((tcp.flags & openvpn::TCPHeader::FLAG_SYN) == 0) {
                if (ephemeral == ephemerals_.end())
                    break;
                EphemeralUsed(four);
                Forge(span, tcp, ephemeral->second.socket_, local_);
                capture_->Land(subset, false);
            } else if (ephemeral == ephemerals_.end()) {
                auto port(ephemerals_.size());
                if (port >= 65535) {
                    auto old_four(*lru_.begin());
                    auto old_ephemeral(ephemerals_.find(old_four));
                    port = old_ephemeral->second.socket_.Port();
                    RemoveEmphemeral(old_four);
                }
                Socket socket(remote_, port);
                auto &flow(flows_[socket]);
                orc_insist(flow == nullptr);
                flow = Make<Flow>(this, four);
                lru_.push_back(four);
                auto lru_iter(std::prev(lru_.end()));
                ephemerals_.emplace(four, Ephemeral_{socket, lru_iter});
                Spawn([
                    beam = std::move(beam),
                    flow,
                    four,
                    socket,
                    span,
                    &tcp,
                this]() mutable -> task<void> {
                    bool reset(false);

                    try {
                        // XXX: it seems strange that Connect takes a string and not a Host
                        co_await origin_->Connect(flow->up_, four.Target().Host().String(), std::to_string(four.Target().Port()));
                    } catch (const std::exception &error) {
                        Log() << error.what() << std::endl;
                        reset = true;
                    }

                    if (reset)
                        Reset(four.Target(), four.Source(), 0, boost::endian::big_to_native(tcp.seq) + 1);
                    else {
                        Forge(span, tcp, socket, local_);
                        capture_->Land(beam, false);
                    }
                });
            }

            co_return true;
        } break;

        case openvpn::IPCommon::UDP: {
            auto &udp(span.cast<openvpn::UDPHeader>(length));

            Socket source(boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(udp.source));
            auto &punch(udp_[source]);
            if (punch == nullptr) {
                auto sink(std::make_unique<Sink<Punch, Opening, BufferSewer>>(this, source));
                co_await origin_->Unlid(sink.get());
                punch = std::move(sink);
            }

            uint16_t offset(length + sizeof(openvpn::UDPHeader));
            uint16_t size(boost::endian::big_to_native(udp.len) - sizeof(openvpn::UDPHeader));
            Socket destination(boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(udp.dest));
            try {
                co_await punch->Send(subset.subset(offset, size), destination);
            } catch (...) {
                // XXX: this is a hack. test on Travis' device
                Log() << "FAIL TO SEND UDP from " << source << " to " << destination << std::endl;
            }

            co_return true;
        } break;

        case openvpn::IPCommon::ICMPv4: {
            if (Verbose)
                Log() << "ICMP" << subset << std::endl;
            co_return true;
        } break;
    }

    co_return false;
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
    Capture *const capture_;

  protected:
    virtual Pump *Inner() = 0;

    void Land(const Buffer &data) override {
        return capture_->Land(data, true);
    }

    void Stop(const std::string &error) override {
    }

  public:
    Pass(Capture *capture) :
        capture_(capture)
    {
    }

    task<bool> Send(const Beam &beam) override {
        co_await Inner()->Send(beam);
        co_return true;
    }
};

task<Sunk<> *> Capture::Start() {
    auto pass(std::make_unique<Sink<Pass>>(this));
    auto backup(pass.get());
    internal_ = std::move(pass);
    co_return backup;
}

static duk_ret_t print(duk_context *ctx) {
    duk_push_string(ctx, " ");
    duk_insert(ctx, 0);
    duk_join(ctx, duk_get_top(ctx) - 1);
    Log() << duk_safe_to_string(ctx, -1) << std::endl;
    return 0;
}

static task<void> Single(Sunk<> *sunk, Heap &heap, Network &network, const S<Origin> &origin, const Beam &argument, const Host &local, unsigned hop) {
    std::string hops("hops[" + std::to_string(hop) + "]");
    auto protocol(heap.eval<std::string>(hops + ".protocol"));
    if (false) {
    } else if (protocol == "orchid") {
        Secret secret(Bless(heap.eval<std::string>(hops + ".secret")));
        Address funder(heap.eval<std::string>(hops + ".funder"));
        co_await network.Random(sunk, origin, argument, secret, funder);
    } else if (protocol == "openvpn") {
        auto ovpnfile(heap.eval<std::string>(hops + ".ovpnfile"));
        auto username(heap.eval<std::string>(hops + ".username"));
        auto password(heap.eval<std::string>(hops + ".password"));
        co_await Connect(sunk, origin, local, ovpnfile, username, password);
    }
}

task<void> Capture::Start(const std::string &path) {
    std::string config;
    boost::filesystem::load_string_file(path, config);

    Heap heap;

    duk_push_c_function(heap, &print, 1);
    duk_put_global_string(heap, "print");

    heap.eval<void>(R"(
        eth_directory = "0xd87e0ee1a59841de2ac78c17209db97e27651985";
        eth_location = "0xE214330bDd412F07d8FC4d4960698c0D657e1774";
        eth_curator = "0x55Abb3CE20ABbC38444e0A200dDE7fC0388b76a5";
        eth_argument = "2b1ce95573ec1b927a90cb488db113b40eeb064a";
        rpc = "https://cloudflare-eth.com:443/";
        hops = [];
        //stun = "stun:stun.l.google.com:19302";
    )");

    heap.eval<void>(config);

    S<Origin> origin(Break<Local>());

    auto hops(unsigned(heap.eval<double>("hops.length")));
    if (hops == 0)
        co_return co_await Start(std::move(origin));

    Network network(heap.eval<std::string>("rpc"), Address(heap.eval<std::string>("eth_directory")), Address(heap.eval<std::string>("eth_location")), Address(heap.eval<std::string>("eth_curator")));
    Beam argument(Bless(heap.eval<std::string>("eth_argument")));

    auto host(origin->Host());

    for (unsigned i(0); i != hops - 1; ++i) {
        auto remote(Break<Sink<Remote>>());
        co_await Single(remote.get(), heap, network, origin, argument, remote->Host(), i);
        remote->Open();
        origin = remote;
    }

    auto sunk(co_await Start());
    co_await Single(sunk, heap, network, origin, argument, host, hops - 1);
}

}
