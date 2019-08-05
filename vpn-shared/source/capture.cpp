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
#include "transport.hpp"
#include "monitor.hpp"

namespace orc {

Analyzer::~Analyzer() = default;

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
                "l4_protocol" integer,
                "protocol" string,
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
    Statement<std::string, sqlite3_int64> update_hostname_;
    Statement<std::string, sqlite3_int64> update_protocol_;
    DnsLog dns_log_;
    std::map<Five, sqlite3_int64> flows_;

  public:
    Logger(const std::string &path) :
        database_(path),
        insert_(database_, R"(
            insert into flow (
                "start", "l4_protocol", "src_addr", "src_port", "dst_addr", "dst_port"
            ) values (
                julianday('now'), ?, ?, ?, ?, ?
            )
        )"),
        update_hostname_(database_, R"(
            update flow set hostname = ? where _rowid_ = ?
        )"),
        update_protocol_(database_, R"(
            update flow set protocol = ? where _rowid_ = ?
        )")
    {
    }

    void Analyze(Span<> &span) override {
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

    void AnalyzeIncoming(Span<> &span) override {
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

    std::string L4ProtocolToString(uint8_t protocol) {
        switch (protocol) {
        case IPPROTO_UDP: return "UDP";
        case IPPROTO_TCP: return "TCP";
        case IPPROTO_ICMP: return "ICMP";
        case IPPROTO_IGMP: return "IGMP";
        default: return "???";
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


        update_protocol_(L4ProtocolToString(five.Protocol()), row_id);

        auto hostname(dns_log_.find(target.Host()));
        if (hostname != dns_log_.end()) {
            update_hostname_(hostname->second, row_id);
        }
    }

    void GotHostname(Five const &five, const std::string &hostname) override {
        auto flow(flows_.find(five));
        if (flow == flows_.end()) {
            orc_assert(false);
            return;
        }
        update_hostname_(hostname, flow->second);
    }

    void GotProtocol(Five const &five, const std::string &protocol) override {
        auto flow(flows_.find(five));
        if (flow == flows_.end()) {
            orc_assert(false);
            return;
        }
        update_protocol_(protocol, flow->second);
    }
};

class Route :
    public BufferDrain,
    public Pipe
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
    Route(Sync *sync) :
        sync_(sync)
    {
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await Inner()->Send(data);
    }
};

void Capture::Land(const Buffer &data) {
    //Log() << "\e[35;1mSEND " << data.size() << " " << data << "\e[0m" << std::endl;
    Beam beam(data);
    Span span(beam.data(), beam.size());

    // analyze/monitor data

    analyzer_->Analyze(span);

    if (route_) Spawn([this, beam = std::move(beam)]() -> task<void> {
        co_return co_await route_->Send(beam);
    });
}

void Capture::Stop(const std::string &error) {
    orc_insist(false);
}

void Capture::Send(const Buffer &data) {
    //Log() << "\e[33;1mRECV " << data.size() << " " << data << "\e[0m" << std::endl;

    Beam beam(data);
    Span span(beam.data(), beam.size());
    analyzer_->AnalyzeIncoming(span);

    Spawn([this, data = Beam(data)]() -> task<void> {
        co_return co_await Inner()->Send(data);
    });
}

Capture::Capture(const std::string &local) :
    analyzer_(std::make_unique<Logger>(Group() + "/analysis.db")),
    local_(openvpn::IPv4::Addr::from_string(local).to_uint32())
{
}

Capture::~Capture() = default;

task<void> Capture::Start() {
    co_return;
}

task<void> Capture::Start(std::string ovpnfile, std::string username, std::string password) {
    auto origin(co_await Setup());
    auto route(std::make_unique<Sink<Route>>(this));
    co_await Connect(route.get(), std::move(origin), local_, std::move(ovpnfile), std::move(username), std::move(password));
    route_ = std::move(route);
}

}
