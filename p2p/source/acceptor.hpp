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
    public Valve,
    public Sewer<asio::ip::tcp::socket>
{
  private:
    asio::ip::tcp::acceptor acceptor_;

  protected:
    void Stop(const std::string &error = std::string()) override {
        Valve::Stop();
    }

  public:
    template <typename... Args_>
    Acceptor(Args_ &&...args) :
        acceptor_(Context(), std::forward<Args_>(args)...)
    {
    }

    asio::ip::tcp::acceptor *operator ->() {
        return &acceptor_;
    }

    Socket Local() const {
        return acceptor_.local_endpoint();
    }

    task<bool> Next() {
        asio::ip::tcp::socket connection(Context());
        asio::ip::tcp::endpoint endpoint;

        try {
            co_await acceptor_.async_accept(connection, endpoint, Token());
        } catch (const asio::system_error &error) {
            const auto code(error.code());
            if (code == asio::error::eof)
                Stop();
            else {
                const std::string what(error.what());
                orc_assert(!what.empty());
                Stop(what);
            }
            co_return false;
        }

        connection.non_blocking(true);
        Land(std::move(connection), endpoint);
        co_return true;
    }

    void Open() {
        Spawn([this]() -> task<void> {
            while (co_await Next());
        });
    }

    void Open(const Socket &socket) {
        acceptor_.open(asio::ip::tcp::v4());
        acceptor_.bind({socket.Host(), socket.Port()});
        acceptor_.listen();
        acceptor_.non_blocking(true);
        Open();
    }

    task<void> Shut() override {
        acceptor_.close();
        co_await Valve::Shut();
    }
};

}

#endif//ORCHID_ACCEPTOR_HPP
