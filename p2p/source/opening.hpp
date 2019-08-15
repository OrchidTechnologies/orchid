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


#ifndef ORCHID_OPENING_HPP
#define ORCHID_OPENING_HPP

#include <asio/ip/udp.hpp>

#include <cppcoro/async_manual_reset_event.hpp>
#include <cppcoro/async_mutex.hpp>

#include "baton.hpp"
#include "link.hpp"
#include "sewer.hpp"
#include "socket.hpp"
#include "task.hpp"

namespace orc {

class Opening final {
  private:
    BufferSewer *const drain_;
    asio::ip::udp::socket connection_;

  public:
    template <typename... Args_>
    Opening(BufferSewer *drain, Args_ &&...args) :
        drain_(drain),
        connection_(Context(), std::forward<Args_>(args)...)
    {
    }

    asio::ip::udp::socket *operator ->() {
        return &connection_;
    }

    void Start() {
        Spawn([this]() -> task<void> {
            for (;;) {
                asio::ip::udp::endpoint endpoint;

                char data[2048];
                size_t writ;
                try {
                    writ = co_await connection_.async_receive_from(asio::buffer(data), endpoint, Token());
                } catch (const asio::system_error &error) {
                    orc_adapt(error);
                }

                Subset region(data, writ);
                if (Verbose)
                    Log() << "\e[33mRECV " << writ << " " << region << "\e[0m" << std::endl;
                drain_->Land(region, endpoint);
            }
        });
    }

    void Connect(const Socket &socket) {
        connection_.open(asio::ip::udp::v4());
        connection_.non_blocking(true);
        connection_.bind({socket.Host(), socket.Port()});
        Start();
    }

    Socket Local() const {
        return connection_.local_endpoint();
    }

    task<void> Send(const Buffer &data, const Socket &socket) {
        auto writ(co_await connection_.async_send_to(Sequence(data), {socket.Host(), socket.Port()}, Token()));
        orc_assert_(writ == data.size(), "orc_assert(" << writ << " {writ} == " << data.size() << " {data.size()})");
    }
};

}

#endif//ORCHID_OPENING_HPP
