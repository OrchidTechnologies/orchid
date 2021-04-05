/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2020  The Orchid Authors
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


#ifndef ORCHID_DUPLEX_HPP
#define ORCHID_DUPLEX_HPP

#include <boost/beast/core.hpp>
#include <boost/beast/websocket.hpp>

#include "base.hpp"
#include "locator.hpp"
#include "reader.hpp"

namespace orc {

class Duplex final :
    public Stream
{
  private:
    S<Base> base_;

  protected:
    boost::beast::websocket::stream<boost::beast::tcp_stream> inner_;

  public:
    Duplex(S<Base> base);

    decltype(inner_) *operator ->() {
        return &inner_;
    }

    task<size_t> Read(const Mutables &buffers) override;

    task<boost::asio::ip::tcp::endpoint> Open(const Locator &locator);

    void Shut() noexcept override;

    task<void> Send(const Buffer &data) override;
};

}

#endif//ORCHID_DUPLEX_HPP
