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


#include <boost/filesystem/operations.hpp>

#include <cppcoro/async_latch.hpp>
#include <cppcoro/async_mutex.hpp>

#include <openvpn/addr/ipv4.hpp>

#include <dns.h>

#include "acceptor.hpp"
#include "boring.hpp"
#include "datagram.hpp"
#include "capture.hpp"
#include "client0.hpp"
#include "client1.hpp"
#include "connection.hpp"
#include "database.hpp"
#include "forge.hpp"
#include "heap.hpp"
#include "load.hpp"
#include "local.hpp"
#include "monitor.hpp"
#include "network.hpp"
#include "oracle.hpp"
#include "origin.hpp"
#include "port.hpp"
#include "retry.hpp"
#include "remote.hpp"
#include "syscall.hpp"
#include "trace.hpp"
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
        const auto application(std::get<0>(Statement<One<int32_t>>(*this, R"(pragma application_id)")()));
        orc_assert(application == 0);

        Statement<Skip>(*this, R"(pragma journal_mode = wal)")();
        Statement<Skip>(*this, R"(pragma secure_delete = on)")();
        Statement<None>(*this, R"(pragma synchronous = normal)")();

        Statement<None>(*this, R"(begin)")();

        const auto version(std::get<0>(Statement<One<int32_t>>(*this, R"(pragma user_version)")()));
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

class Nameless :
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
    Nameless(const std::string &path) :
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
                    if (Verbose)
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
            const auto length(openvpn::IPv4Header::length(ip4.version_len));
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
        const auto row_id(insert_(five.Protocol(),
            source.Host().operator uint32_t(), source.Port(),
            destination.Host().operator uint32_t(), destination.Port()
        ));
        flow_to_row_.emplace(five, row_id);

        auto hostname(dns_log_.find(destination.Host()));
        if (hostname != dns_log_.end()) {
            update_hostname_(hostname->second, row_id);
        }
    }

    void GotHostname(Five const &five, const std::string_view hostname) override {
        const auto flow_row(flow_to_row_.find(five));
        orc_assert(flow_row != flow_to_row_.end());
        update_hostname_(hostname, flow_row->second);
    }

    void GotProtocol(Five const &five, const std::string_view protocol, const std::string_view protocol_chain) override {
        const auto flow_row(flow_to_row_.find(five));
        orc_assert(flow_row != flow_to_row_.end());
        auto flow_protocol_chain(flow_to_protocol_chain_.find(five));
        if (flow_protocol_chain != flow_to_protocol_chain_.end()) {
            const auto s(flow_protocol_chain->second);
            const auto specificity(std::count(protocol_chain.begin(), protocol_chain.end(), ':'));
            const auto current_specificity(std::count(s.begin(), s.end(), ':'));
            if (specificity < current_specificity)
                return;
        }
        flow_to_protocol_chain_[five] = protocol_chain;
        update_protocol_(protocol, flow_row->second);
    }
};

void Capture::Land(const Buffer &data) {
    //Log() << "\e[35;1mSEND " << data.size() << " " << data << "\e[0m" << std::endl;
    if (internal_) up_.Hatch([&]() noexcept { return [this, data = Beam(data)]() mutable -> task<void> {
        if (co_await internal_->Send(data) && analyzer_ != nullptr)
            analyzer_->Analyze(data.span());
    }; }, __FUNCTION__);
}

void Capture::Stop(const std::string &error) noexcept {
    orc_insist_(false, error);
    Valve::Stop();
}

void Capture::Land(const Buffer &data, bool analyze) {
    //Log() << "\e[33;1mRECV " << data.size() << " " << data << "\e[0m" << std::endl;
    down_.Hatch([&]() noexcept { return [this, data = Beam(data), analyze]() mutable -> task<void> {
        co_await Inner().Send(data);
        if (analyze && analyzer_ != nullptr)
            analyzer_->AnalyzeIncoming(data.span());
    }; }, __FUNCTION__);
}

Capture::Capture(const Host &local) :
    Valve(typeid(*this).name()),
    local_(local),
    up_(32)
{
    router_(http::verb::get, "/connected", [&](Request request) -> task<Response> {
        co_return Respond(request, http::status::ok, "application/json", locked_()->connected_ ? "true" : "false");
    });
}

Capture::~Capture() {
orc_trace();
}


class Hole {
  public:
    virtual ~Hole() = default;

    virtual void Land(const Buffer &data) = 0;
};

class Punch :
    public BufferSewer,
    public Sunken<Opening>
{
  private:
    Hole *const hole_;
    const Socket socket_;

  protected:
    void Land(const Buffer &data, Socket socket) override {
        hole_->Land(Datagram(socket, socket_, data));
    }

    void Stop(const std::string &error) noexcept override {
        orc_insist_(false, error);
    }

  public:
    Punch(Hole *hole, Socket socket) :
        hole_(hole),
        socket_(socket)
    {
    }

    virtual ~Punch() = default;

    task<void> Send(const Buffer &data, const Socket &socket) {
        co_return co_await Inner().Send(data, socket);
    }
};

class Plant {
  public:
    virtual task<void> Pull(const Four &four) noexcept = 0;
};

class Flow {
  public:
    Plant *const plant_;
    const Four four_;

    cppcoro::async_latch latch_;
    U<Stream> up_;
    U<Stream> down_;

  private:
    void Splice(Stream *input, Stream *output) {
        Spawn([input, output, &latch = latch_]() noexcept -> task<void> {
            Beam beam(2048);
            for (;;) {
                size_t writ;
                if (orc_ignore({ writ = co_await input->Read(asio::buffer(beam.data(), beam.size())); }) || writ == 0)
                    break;
                if (orc_ignore({ co_await output->Send(beam.subset(0, writ)); }))
                    break;
            }

            output->Shut();
            latch.count_down();
        }, __FUNCTION__);
    }

  public:
    Flow(Plant *plant, Four four) :
        plant_(plant),
        four_(four),
        latch_(2)
    {
    }

    void Open() {
        Spawn([this]() noexcept -> task<void> {
            co_await latch_;
            co_await plant_->Pull(four_);
        }, __FUNCTION__);

        Splice(up_.get(), down_.get());
        Splice(down_.get(), up_.get());
    }
};

class Transform :
    public Internal,
    public Acceptor,
    public Plant,
    public Hole
{
  private:
    Capture *const capture_;
    const S<Origin> origin_;

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

    void RemoveFlow(const Four &four) noexcept {
        const auto ephemeral(ephemerals_.find(four));
        orc_insist(ephemeral != ephemerals_.end());
        const auto flow(flows_.find(ephemeral->second.socket_));
        orc_insist(flow != flows_.end());
        flows_.erase(flow);
    }

    void RemoveEmphemeral(const Four &four) {
        const auto ephemeral(ephemerals_.find(four));
        orc_insist(ephemeral != ephemerals_.end());
        flows_.erase(ephemeral->second.socket_);
        lru_.erase(ephemeral->second.lru_iter_);
        ephemerals_.erase(ephemeral);
    }

  protected:
    void Land(asio::ip::tcp::socket connection, Socket socket) override {
        Spawn([this, connection = std::move(connection), socket]() mutable noexcept -> task<void> {
            const auto flow(co_await [&]() noexcept -> task<S<Flow>> {
                const auto lock(co_await meta_.scoped_lock_async());
                const auto flow(flows_.find(socket));
                if (flow == flows_.end())
                    co_return nullptr;
                co_return flow->second;
            }());
            if (flow == nullptr)
                co_return;
            flow->down_ = std::make_unique<Connection>(std::move(connection));
            flow->Open();
        }, __FUNCTION__);
    }

    void Stop(const std::string &error) noexcept override {
        orc_insist_(false, error);
    }

  public:
    Transform(Capture *capture, S<Origin> origin) :
        Internal(typeid(*this).name()),
        capture_(capture),
        origin_(std::move(origin))
    {
    }

    void Connect(const Host &local);
    task<void> Shut() noexcept override;

    void Land(const Buffer &data) override;
    task<bool> Send(const Beam &data) override;

    void EphemeralUsed(const Four &four) {
        auto emphemeral_iter(ephemerals_.find(four));
        lru_.erase(emphemeral_iter->second.lru_iter_);
        lru_.push_back(emphemeral_iter->first);
        emphemeral_iter->second.lru_iter_ = std::prev(lru_.end());
    }

    task<void> Pull(const Four &four) noexcept override {
        const auto lock(co_await meta_.scoped_lock_async());
        RemoveFlow(four);
    }

    // https://www.snellman.net/blog/archive/2016-02-01-tcp-rst/
    // https://superuser.com/questions/1056492/rst-sequence-number-and-window-size/1075512
    void Reset(const Socket &source, const Socket &destination, uint32_t sequence, uint32_t acknowledge) noexcept {
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

void Transform::Connect(const Host &local) {
    Acceptor::Open({local, 0});
    local_ = Local();
    // XXX: this is sickening
    remote_ = asio::ip::address_v4(local_.Host().operator uint32_t() + 1);
}

task<void> Transform::Shut() noexcept {
    orc_insist(false);
}

void Transform::Land(const Buffer &data) {
    return capture_->Land(data, true);
}

task<bool> Transform::Send(const Beam &data) {
    Beam beam(data);
    auto span(beam.span());
    Subset subset(span);

    const auto &ip4(span.cast<openvpn::IPv4Header>());
    const auto length(openvpn::IPv4Header::length(ip4.version_len));

    switch (ip4.protocol) {
        case openvpn::IPCommon::TCP: {
            if (Verbose)
                Log() << "TCP:" << subset << std::endl;
            auto &tcp(span.cast<openvpn::TCPHeader>(length));

            const Four four(
                {boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(tcp.source)},
                {boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(tcp.dest)}
            );

            if (four.Source() == local_) {
                const auto lock(co_await meta_.scoped_lock_async());
                const auto flow(flows_.find(four.Target()));
                if (flow == flows_.end())
                    break;
                orc_insist(flow->second != nullptr);
                const auto &original(flow->second->four_);
                EphemeralUsed(original);
                Forge(span, tcp, original.Target(), original.Source());
                capture_->Land(subset, true);
                co_return false;
            }

            const auto lock(co_await meta_.scoped_lock_async());
            const auto ephemeral(ephemerals_.find(four));

            if ((tcp.flags & openvpn::TCPHeader::FLAG_SYN) == 0) {
                if (ephemeral == ephemerals_.end())
                    break;
                EphemeralUsed(four);
                Forge(span, tcp, ephemeral->second.socket_, local_);
                capture_->Land(subset, false);
            } else if (ephemeral == ephemerals_.end()) {
                // port 0 is not valid
                auto port(ephemerals_.size() + 1);
                if (port >= 65535 - 1) {
                    const auto old_four(*lru_.begin());
                    auto old_ephemeral(ephemerals_.find(old_four));
                    port = old_ephemeral->second.socket_.Port();
                    RemoveEmphemeral(old_four);
                }
                Socket socket(remote_, port);
                auto &flow(flows_[socket]);
                orc_insist(flow == nullptr);
                flow = Make<Flow>(this, four);
                lru_.push_back(four);
                const auto lru_iter(std::prev(lru_.end()));
                ephemerals_.emplace(four, Ephemeral_{socket, lru_iter});
                Spawn([
                    beam = std::move(beam),
                    flow,
                    four,
                    socket,
                    span,
                    &tcp,
                this]() mutable noexcept -> task<void> {
                    if (orc_ignore({ flow->up_ = co_await origin_->Connect(four.Target()); }))
                        Reset(four.Target(), four.Source(), 0, boost::endian::big_to_native(tcp.seq) + 1);
                    else {
                        Forge(span, tcp, socket, local_);
                        capture_->Land(beam, false);
                    }
                }, __FUNCTION__);
            }

            co_return true;
        } break;

        case openvpn::IPCommon::UDP: {
            auto &udp(span.cast<openvpn::UDPHeader>(length));

            Socket source(boost::endian::big_to_native(ip4.saddr), boost::endian::big_to_native(udp.source));
            auto &punch(udp_[source]);
            if (punch == nullptr) {
                auto sink(std::make_unique<Sink<Punch, BufferSewer>>(this, source));
                co_await origin_->Unlid(*sink);
                punch = std::move(sink);
            }

            const uint16_t offset(length + sizeof(openvpn::UDPHeader));
            const uint16_t size(boost::endian::big_to_native(udp.len) - sizeof(openvpn::UDPHeader));
            const Socket destination(boost::endian::big_to_native(ip4.daddr), boost::endian::big_to_native(udp.dest));
            co_await punch->Send(subset.subset(offset, size), destination);

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

void Capture::Start(S<Origin> origin) {
    auto transform(std::make_unique<Covered<Transform>>(this, std::move(origin)));
    transform->Connect(local_);
    internal_ = std::move(transform);
}

class Pass :
    public Internal,
    public BufferDrain,
    public Sunken<Pump<Buffer>>
{
  private:
    Capture *const capture_;

  protected:
    void Land(const Buffer &data) override {
        return capture_->Land(data, true);
    }

    void Stop(const std::string &error) noexcept override {
        orc_insist_(error.empty(), error);
        Internal::Stop();
    }

  public:
    Pass(Capture *capture) :
        Internal(typeid(*this).name()),
        capture_(capture)
    {
    }

    task<void> Shut() noexcept override {
        co_await Sunken::Shut();
        co_await Internal::Shut();
    }

    task<bool> Send(const Beam &beam) override {
        co_await Inner().Send(beam);
        co_return true;
    }
};

BufferSunk &Capture::Start() {
    auto pass(std::make_unique<Covered<BufferSink<Pass>>>(this));
    auto &backup(*pass);
    internal_ = std::move(pass);
    return backup;
}

static JSValue Print(JSContext *context, JSValueConst self, int argc, JSValueConst *argv) { try {
    orc_assert(argc == 1);
    size_t size;
    const auto data(JS_ToCStringLen(context, &size, argv[0]));
    if (data == nullptr)
        return JS_EXCEPTION;
    _scope({ JS_FreeCString(context, data); });
    Log() << std::string(data, size) << std::endl;
    return JS_UNDEFINED;
} catch (const std::exception &error) {
    // NOLINTNEXTLINE (cppcoreguidelines-pro-type-vararg)
    return JS_ThrowInternalError(context, "%s", error.what());
} }

static task<void> Single(BufferSunk &sunk, Heap &heap, const S<Network> &network, const S<Origin> &origin, const Host &local, unsigned hop, const boost::filesystem::path &group, const Locator &locator, const S<Updated<Prices>> &oracle, const Token &oxt) { orc_block({
    const std::string hops("hops[" + std::to_string(hop) + "]");
    const auto protocol(heap.eval<std::string>(hops + ".protocol"));
    if (false) {

    } else if (protocol == "orchid") {
        const Address lottery(heap.eval<std::string>(hops + ".lottery", "0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1"));
        const auto secret(orc_value(return, Bless<Secret>(heap.eval<std::string>(hops + ".secret")), "parsing .secret"));
        const Address funder(heap.eval<std::string>(hops + ".funder"));
        const std::string curator(heap.eval<std::string>(hops + ".curator"));
        auto chain(co_await Chain::New({locator, origin}, {}, uint256_t(heap.eval<double>(hops + ".chainid", 1))));
        const auto provider(co_await network->Select(curator, heap.eval<std::string>(hops + ".provider", "0x0000000000000000000000000000000000000000")));
        auto &client(*co_await Client0::Wire(sunk, oracle, oxt, lottery, secret, funder));
        co_await client.Open(provider, origin);

    } else if (protocol == "orch1d") {
        const Address lottery(heap.eval<std::string>(hops + ".lottery", "0xff9978B7b309021D39a76f52Be377F2B95D72394"));
        const auto secret(orc_value(return, Bless<Secret>(heap.eval<std::string>(hops + ".secret")), "parsing .secret"));
        const Address funder(heap.eval<std::string>(hops + ".funder"));
        const std::string curator(heap.eval<std::string>(hops + ".curator"));
        const auto chain(uint256_t(heap.eval<double>(hops + ".chainid", 1)));
        const auto provider(co_await network->Select(curator, heap.eval<std::string>(hops + ".provider", "0x0000000000000000000000000000000000000000")));
        Locator locator(heap.eval<std::string>(hops + ".rpc"));
        std::string currency(heap.eval<std::string>(hops + ".currency"));
        auto &client(*co_await Client1::Wire(sunk, oracle, co_await Market::New(5*60*1000, chain, origin, std::move(locator), std::move(currency)), lottery, secret, funder));
        co_await client.Open(provider, origin);

    } else if (protocol == "openvpn") {
        co_await Connect(sunk, origin, local.operator uint32_t(),
            heap.eval<std::string>(hops + ".ovpnfile"),
            heap.eval<std::string>(hops + ".username"),
            heap.eval<std::string>(hops + ".password")
        );
    } else if (protocol == "wireguard") {
        co_await Guard(sunk, origin, local.operator uint32_t(), heap.eval<std::string>(hops + ".config"));
    } else orc_assert_(false, "unknown hop protocol: " << protocol);
}, "building hop #" << hop); }

void Capture::Start(const std::string &path) {
    Heap heap; {
        Value global(heap, JS_GetGlobalObject(heap));
        JS_SetPropertyStr(heap, global, "print", JS_NewCFunction(heap, &Print, "print", 1));
    }

    heap.eval<void>(R"(
        eth_directory = "0x918101FB64f467414e9a785aF9566ae69C3e22C5";
        eth_location = "0xEF7bc12e0F6B02fE2cb86Aa659FdC3EBB727E0eD";
        eth_winratio = 0;
        hops = [];
        logdb = "analysis.db";
        control = "";
        //stun = "stun:stun.l.google.com:19302";
    )");

    heap.eval<void>(Load(path));

    const auto group(boost::filesystem::path(path).parent_path());

#ifndef _WIN32
    const auto control(heap.eval<std::string>("control"));
    if (!control.empty())
        router_.Run(boost::filesystem::absolute(control, group).string());
#endif

    const auto analysis(heap.eval<std::string>("logdb"));
    if (!analysis.empty())
        analyzer_ = std::make_unique<Nameless>(boost::filesystem::absolute(analysis, group).string());

    S<Origin> local(Break<Local>());

    const auto hops(unsigned(heap.eval<double>("hops.length")));
    if (hops == 0) {
        locked_()->connected_ = true;
        return Start(std::move(local));
    }

#if 0
    auto remote(Break<BufferSink<Remote>>());
    const auto host(remote->Host());
    auto &sunk(*remote);
#else
    S<Remote> remote;
    const auto host(local->Host());
    auto &sunk(Start());
#endif

    auto code([this, heap = std::move(heap), hops, local = std::move(local), host, group](BufferSunk &sunk) mutable -> task<void> {
        locked_()->connected_ = false;

        const Locator locator(heap.eval<std::string>("rpc"));
        const auto directory(Address(heap.eval<std::string>("eth_directory")));
        const auto location(Address(heap.eval<std::string>("eth_location")));

        const auto chain(co_await Chain::New({locator, local}, {}, 1));
        const auto network(Break<Network>(chain, directory, location));

        const unsigned milliseconds(5*60*1000);
        const auto [oracle, oxt] = *co_await Parallel(Oracle(milliseconds, chain), Token::OXT(5*60*1000, chain));

        auto origin(local);

        for (unsigned i(0); i != hops - 1; ++i) {
            auto remote(Break<BufferSink<Remote>>());
            co_await Single(*remote, heap, network, origin, remote->Host(), i, group, locator, oracle, oxt);
            remote->Open();
            origin = std::move(remote);
        }

        co_await Single(sunk, heap, network, origin, host, hops - 1, group, locator, oracle, oxt);
        locked_()->connected_ = true;
    });

    auto &retry(sunk.Wire<Retry<decltype(code)>>(std::move(code)));
    retry.Open();

    if (remote != nullptr) {
        remote->Open();
        Start(std::move(remote));
    }
}

task<void> Capture::Shut() noexcept {
    co_await Parallel(up_.Shut(), down_.Shut());
    if (internal_ != nullptr)
        co_await internal_->Shut();
orc_trace();
    analyzer_ = nullptr;
    exit(0);
    co_await Sunken::Shut();
orc_trace();
    co_await Valve::Shut();
}

}
