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

    void Analyze(Span<> &span) override {
        auto &ip4(span.cast<openvpn::IPv4Header>());
        if (ip4.protocol == openvpn::IPCommon::TCP) {
            auto length(openvpn::IPv4Header::length(ip4.version_len));
            auto &tcp(span.cast<openvpn::TCPHeader>(length));
            if ((tcp.flags & openvpn::TCPHeader::FLAG_SYN) != 0) {
                auto destination(boost::endian::big_to_native(ip4.daddr));
                Log() << "TCP=" << std::hex << destination << ":" << std::dec << boost::endian::big_to_native(tcp.dest) << std::endl;
                //insert_(destination);
            }
        }
        monitor(span.data(), span.size(), *this);
    }

    void AddFlow(Five const &five) override {
        auto flow(flows_.find(five));
        if (flow != flows_.end())
            return;
        const auto &source(five.Source());
        const auto &target(five.Target());
        // XXX: IPv6
        flows_.emplace(five, insert_(five.Protocol(),
            source.Host().to_v4().to_uint(), source.Port(),
            target.Host().to_v4().to_uint(), target.Port()
        ));
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
