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


#include <sqlite3.h>

#include <openvpn/addr/ipv4.hpp>

#include "capture.hpp"
#include "directory.hpp"
#include "forge.hpp"
#include "transport.hpp"
#include "monitor.hpp"

#define orc_sqlstep(expr) ({ \
    auto _value(expr); \
    orc_assert_(_value == 0 || _value >= 100 && _value < 200, "orc_sqlcall(" #expr ") " << _value << ":" << sqlite3_errmsg(database_)); \
_value; })

#define orc_sqlcall(expr) \
    orc_assert(orc_sqlstep(expr) == SQLITE_OK)

namespace orc {

Analyzer::~Analyzer() {
}

template <typename... Args_>
class Statement {
  private:
    sqlite3 *database_;
    sqlite3_stmt *statement_;

    template <unsigned Index_>
    void Bind() {
    }

#define orc_bind(name, type, ...) \
    template <unsigned Index_, typename... Rest_> \
    void Bind(type value, Rest_ &&...rest) { \
        orc_sqlcall(sqlite3_bind_ ## name(statement_, Index_, ## __VA_ARGS__)); \
        return Bind<Index_ + 1>(std::forward<Rest_>(rest)...); \
    }

    orc_bind(double, double, value)
    orc_bind(int, int, value)
    orc_bind(int64, int64_t, value)
    orc_bind(null, nullptr_t)
    orc_bind(text, const char *, value, -1, SQLITE_TRANSIENT)
    orc_bind(text, const std::string &, value.c_str(), value.size(), SQLITE_TRANSIENT)

  public:
    Statement() :
        statement_(nullptr)
    {
    }

    Statement(sqlite3 *database, const char *code) :
        database_(database)
    {
        orc_sqlcall(sqlite3_prepare_v2(database_, code, -1, &statement_, NULL));
    }

    ~Statement() { try {
        if (statement_ != nullptr)
            orc_sqlcall(sqlite3_finalize(statement_));
    } catch (...) {
        orc_insist(false);
    } }

    void operator ()(Args_ &&...args) {
        orc_sqlcall(sqlite3_reset(statement_));
        Bind<1>(std::forward<Args_>(args)...);
        orc_assert(orc_sqlstep(sqlite3_step(statement_)) == SQLITE_DONE);
        orc_sqlcall(sqlite3_clear_bindings(statement_));
    }
};

class Database {
  private:
    sqlite3 *database_;

  public:
    Database(const std::string &path) {
        orc_sqlcall(sqlite3_open_v2(path.c_str(), &database_, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL));
    }

    ~Database() { try {
        orc_sqlcall(sqlite3_close(database_));
    } catch (...) {
        orc_insist(false);
    } }

    operator sqlite3 *() const {
        return database_;
    }
};

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
                "address" integer
            );
        )")();
    }
};

class Logger :
    public Analyzer
{
  private:
    LoggerDatabase database_;
    Statement<int64_t> insert_;

  public:
    Logger(const std::string &path) :
        database_(path),
        insert_(database_, R"(
            insert into flow (
                "start", "address"
            ) values (
                julianday('now'), ?
            )
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
                insert_(destination);
            }
        }
        monitor(span.data(), span.size());
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
