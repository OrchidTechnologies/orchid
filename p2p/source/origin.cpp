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


#include "adapter.hpp"
#include "baton.hpp"
#include "connection.hpp"
#include "locator.hpp"
#include "origin.hpp"

namespace orc {

task<std::string> Origin::Request(const std::string &method, const Locator &locator, const std::map<std::string, std::string> &headers, const std::string &data) {
    Sink<Adapter> adapter(orc::Context());
    U<Stream> stream;
    co_await Connect(stream, locator.host_, locator.port_);
    auto socket(adapter.Wire<Inverted>(std::move(stream)));
    socket->Start();
    co_return co_await orc::Request(adapter, method, locator, headers, data);
}

task<Socket> Local::Associate(Sunk<> *sunk, const std::string &host, const std::string &port) {
    auto connection(std::make_unique<Connection<asio::ip::udp::socket>>(Context()));
    auto endpoint(co_await connection->Connect(host, port));
    auto inverted(sunk->Wire<Inverted>(std::move(connection)));
    inverted->Start();
    co_return Socket(endpoint.address().to_string(), endpoint.port());
}

task<Socket> Local::Connect(U<Stream> &stream, const std::string &host, const std::string &port) {
    auto connection(std::make_unique<Connection<asio::ip::tcp::socket>>(Context()));
    auto endpoint(co_await connection->Connect(host, port));
    stream = std::move(connection);
    co_return Socket(endpoint.address().to_string(), endpoint.port());
}

task<Socket> Local::Open(Sunk<Opening, BufferSewer> *sunk) {
    auto opening(sunk->Wire<Opening>());
    opening->Connect({asio::ip::address_v4::any(), 0});
    co_return opening->Local();
}

S<Local> GetLocal() {
    static auto local(Make<Local>());
    return local;
}

}
