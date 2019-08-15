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


#ifndef ORCHID_ACCEPTOR_HPP
#define ORCHID_ACCEPTOR_HPP

#include <asio/ip/tcp.hpp>

#include "baton.hpp"
#include "link.hpp"
#include "sewer.hpp"
#include "task.hpp"

namespace orc {

class Acceptor :
    public Sewer<asio::ip::tcp::socket>
{
  private:
    asio::ip::tcp::acceptor acceptor_;

  public:
    template <typename... Args_>
    Acceptor(Args_ &&...args) :
        acceptor_(Context(), std::forward<Args_>(args)...)
    {
    }

    asio::ip::tcp::acceptor *operator ->() {
        return &acceptor_;
    }

    task<bool> Read() {
        asio::ip::tcp::socket connection(Context());
        asio::ip::tcp::endpoint endpoint;

        try {
            co_await acceptor_.async_accept(connection, endpoint, Token());
        } catch (const asio::system_error &error) {
            auto code(error.code());
            if (code == asio::error::eof)
                Stop();
            else {
                std::string what(error.what());
                orc_assert(!what.empty());
                Stop(what);
            }
            co_return false;
        }

        connection.non_blocking(true);
        Land(std::move(connection), endpoint);
        co_return true;
    }

    void Start() {
        Spawn([this]() -> task<void> {
            while (co_await Read());
        });
    }

    void Connect(const Socket &socket) {
        acceptor_.open(asio::ip::tcp::v4());
        acceptor_.bind({socket.Host(), socket.Port()});
        acceptor_.listen();
        acceptor_.non_blocking(true);
        Start();
    }

    Socket Local() const {
        return acceptor_.local_endpoint();
    }
};

}

#endif//ORCHID_ACCEPTOR_HPP
