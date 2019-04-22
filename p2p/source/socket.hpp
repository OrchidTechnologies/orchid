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

#include <cppcoro/async_mutex.hpp>

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
    cppcoro::async_mutex send_;

  public:
    Socket() :
        socket_(std::make_shared<Type_>(Context()))
    {
    }

    task<void> _(const std::string &host, const std::string &port) {
        auto endpoints(co_await asio::ip::basic_resolver<typename Type_::protocol_type>(Context()).async_resolve({host, port}, Token()));
        for (auto &endpoint : endpoints)
            Log() << endpoint.host_name() << ":" << endpoint.service_name() << " :: " << endpoint.endpoint() << std::endl;
        co_await asio::async_connect(*socket_, endpoints, Token());

        // XXX: the memory management here seems wrong
        Task([socket = socket_, this]() -> task<void> {
            for (;;) {
                char data[2048];
                size_t writ;
                try {
                    writ = co_await socket->async_receive(asio::buffer(data), Token());
                } catch (const asio::error_code &error) {
                    if (error == boost::asio::error::eof)
                        Land();
                    break;
                }

                _assert(writ != 0);
                Beam beam(data, writ);
                //Log() << "\e[33mRECV " << writ << " " << beam << "\e[0m" << std::endl;
                Land(beam);
            }
        });
    }

    ~Socket() {
        socket_->close();
    }

    task<void> Send(const Buffer &data) override {
        //Log() << "\e[35mSEND " << data.size() << " " << data << "\e[0m" << std::endl;
        if (data.empty()) {
            socket_->shutdown(Type_::protocol_type::socket::shutdown_send);
        } else {
            auto lock(co_await send_.scoped_lock_async());
            auto writ(co_await socket_->async_send(Sequence(data), Token()));
            _assert(writ == data.size());
        }
    }
};

}
