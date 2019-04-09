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


#include "baton.hpp"
#include "socket.hpp"
#include "task.hpp"
#include "trace.hpp"

namespace orc {

Socket::Socket() :
    socket_(Context())
{
}

task<void> Socket::_(const std::string &host, const std::string &port) {
    {
        asio::ip::tcp::resolver resolver(Context());
        asio::ip::tcp::resolver::query query(host, port);
        co_await asio::async_connect(socket_, co_await resolver.async_resolve(query, Token()), Token());
    }

    // XXX: the memory management on this is incorrect
    Task([this]() -> task<void> {
        try {
            for (;;) {
                char data[1024];
                size_t writ(co_await socket_.async_receive(asio::buffer(data), Token()));
                Land(Beam(data, writ));
            }
        } catch (const asio::system_error &e) {
            Land();
        }
    });
}

Socket::~Socket() {
    // XXX: this feels (asynchronously) incorrect
    socket_.close();
}

task<void> Socket::Send(const Buffer &data) {
    if (data.empty())
        // XXX: is there really no asynchronous shutdown?
        socket_.shutdown(asio::ip::tcp::socket::shutdown_send);
    else
        co_await socket_.async_send(Sequence(data), Token());
}

}
