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

#include "baton.hpp"
#include "dns.hpp"
#include "link.hpp"
#include "reader.hpp"
#include "task.hpp"

namespace orc {

template <typename Connection_>
class Connection final :
    public Stream
{
  protected:
    Connection_ connection_;

  public:
    template <typename... Args_>
    Connection(Args_ &&...args) noexcept(noexcept(Connection_(std::forward<Args_>(args)...))) :
        connection_(std::forward<Args_>(args)...)
    {
    }

    Connection_ *operator ->() {
        return &connection_;
    }

    task<size_t> Read(Beam &beam) override {
        size_t writ;
        try {
            writ = co_await connection_.async_receive(asio::buffer(beam.data(), beam.size()), Token());
        } catch (const asio::system_error &error) {
            auto code(error.code());
            if (code == asio::error::eof)
                co_return 0;
            orc_adapt(error);
        }

        if (Verbose)
            Log() << "\e[33mRECV " << writ << " " << beam.subset(0, writ) << "\e[0m" << std::endl;
        co_return writ;
    }

    task<boost::asio::ip::basic_endpoint<typename Connection_::protocol_type>> Open(const std::string &host, const std::string &port) {
        const auto endpoints(co_await asio::ip::basic_resolver<typename Connection_::protocol_type>(Context()).async_resolve({host, port}, Token()));
        if (Verbose)
            for (const auto &endpoint : endpoints)
                Log() << endpoint.host_name() << ":" << endpoint.service_name() << " :: " << endpoint.endpoint() << std::endl;
        const auto endpoint(co_await orc_value(co_return co_await, asio::async_connect(connection_, endpoints, Token()),
            "connecting to" << endpoints));
        connection_.non_blocking(true);
        co_return endpoint;
    }

    task<void> Shut() noexcept override {
        try {
            connection_.shutdown(Connection_::protocol_type::socket::shutdown_send);
        } catch (const asio::system_error &error) {
            const auto code(error.code());
            if (code == asio::error::not_connected)
                co_return;
            orc_except({ orc_adapt(error); })
        }
    }

    task<void> Send(const Buffer &data) override {
        if (Verbose)
            Log() << "\e[35mSEND " << data.size() << " " << data << "\e[0m" << std::endl;

        const size_t writ(co_await [&]() -> task<size_t> { try {
            co_return co_await connection_.async_send(Sequence(data), Token());
        } catch (const asio::system_error &error) {
            orc_adapt(error);
        } }());
        orc_assert_(writ == data.size(), "orc_assert(" << writ << " {writ} == " << data.size() << " {data.size()})");
    }
};

}

#endif//ORCHID_CONNECTION_HPP
