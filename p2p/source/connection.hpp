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


#ifndef ORCHID_CONNECTION_HPP
#define ORCHID_CONNECTION_HPP

#include <asio/ip/tcp.hpp>
#include <asio/ip/udp.hpp>

#include <cppcoro/async_manual_reset_event.hpp>
#include <cppcoro/async_mutex.hpp>

#include "baton.hpp"
#include "link.hpp"
#include "task.hpp"

namespace orc {

template <typename Connection_>
class Connection final :
    public Link
{
  private:
    Connection_ connection_;
    cppcoro::async_mutex send_;

  public:
    template <typename... Args_>
    Connection(BufferDrain *drain, Args_ &&...args) :
        Link(drain),
        connection_(Context(), std::forward<Args_>(args)...)
    {
    }

    Connection_ *operator ->() {
        return &connection_;
    }

    void Start() {
        Spawn([this]() -> task<void> {
            for (;;) {
                char data[2048];
                size_t writ;
                try {
                    writ = co_await connection_.async_receive(asio::buffer(data), Token());
                } catch (const asio::error_code &error) {
                    if (error == asio::error::eof)
                        Link::Stop();
                    else {
                        auto message(error.message());
                        orc_assert(!message.empty());
                        Link::Stop(message);
                    }
                    break;
                }

                Beam beam(data, writ);

                if (Verbose)
                    Log() << "\e[33mRECV " << writ << " " << beam << "\e[0m" << std::endl;

                Land(beam);
            }
        });
    }

    task<boost::asio::ip::basic_endpoint<typename Connection_::protocol_type>> Connect(const std::string &host, const std::string &port) {
        auto endpoints(co_await asio::ip::basic_resolver<typename Connection_::protocol_type>(Context()).async_resolve({host, port}, Token()));

        if (Verbose)
            for (auto &endpoint : endpoints)
                Log() << endpoint.host_name() << ":" << endpoint.service_name() << " :: " << endpoint.endpoint() << std::endl;

        auto endpoint(co_await asio::async_connect(connection_, endpoints, Token()));

        Start();

        co_return endpoint;
    }

    ~Connection() override {
_trace();
    }

    task<void> Send(const Buffer &data) override {
        if (Verbose)
            Log() << "\e[35mSEND " << data.size() << " " << data << "\e[0m" << std::endl;

        if (data.empty()) {
            connection_.shutdown(Connection_::protocol_type::socket::shutdown_send);
        } else {
            auto lock(co_await send_.scoped_lock_async());
            auto writ(co_await connection_.async_send(Sequence(data), Token()));
            orc_assert_(writ == data.size(), "orc_assert(" << writ << " {writ} == " << data.size() << " {data.size()})");
        }
    }

    task<void> Shut() override {
        connection_.close();
        co_await Link::Shut();
    }
};

}

#endif//ORCHID_CONNECTION_HPP
