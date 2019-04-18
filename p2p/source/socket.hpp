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


#include <asio/ip/tcp.hpp>
#include <asio/ip/udp.hpp>

#include "baton.hpp"
#include "link.hpp"
#include "task.hpp"

namespace orc {

template <typename Type_>
class Socket final :
    public Link
{
  private:
    S<Type_> socket_;

  public:
    Socket() :
        socket_(std::make_shared<Type_>(Context()))
    {
    }

    task<void> _(const std::string &host, const std::string &port) {
        co_await asio::async_connect(*socket_, co_await asio::ip::basic_resolver<typename Type_::protocol_type>(Context()).async_resolve({host, port}, Token()), Token());

        // XXX: the memory management here seems wrong
        Task([socket = socket_, this]() -> task<void> {
            try {
                for (;;) {
                    char data[1024];
                    size_t writ(co_await socket->async_receive(asio::buffer(data), Token()));
                    _assert(writ != 0);
                    Land(Beam(data, writ));
                }
            } catch (const asio::error_code &error) {
                if (error == boost::asio::error::eof)
                    Land();
            }
        });
    }

    ~Socket() {
        socket_->close();
    }

    task<void> Send(const Buffer &data) override {
        if (data.empty())
            socket_->shutdown(Type_::protocol_type::socket::shutdown_send);
        else
            co_await socket_->async_send(Sequence(data), Token());
    }
};

}
