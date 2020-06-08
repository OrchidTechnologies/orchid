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
#include "socket.hpp"
#include "task.hpp"

namespace orc {

template <typename Connection_, bool Close_>
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

        //Log() << "\e[33mRECV " << writ << " " << beam.subset(0, writ) << "\e[0m" << std::endl;
        co_return writ;
    }

    task<void> Open(const Socket &endpoint) { orc_block({
        co_await connection_.async_connect(endpoint, Token());
        connection_.non_blocking(true);
    }, "connecting to " << endpoint); }

    void Shut() noexcept override {
        if (Close_)
            connection_.close();
        else try {
            connection_.shutdown(Connection_::shutdown_send);
        } catch (const asio::system_error &error) {
            const auto code(error.code());
            if (code == asio::error::not_connected)
                return;
            orc_except({ orc_adapt(error); })
        }
    }

    task<void> Send(const Buffer &data) override {
        //Log() << "\e[35mSEND " << data.size() << " " << data << "\e[0m" << std::endl;

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
