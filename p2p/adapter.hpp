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


#ifndef ORCHID_ADAPTER_HPP
#define ORCHID_ADAPTER_HPP

#include "link.hpp"

namespace orc {

class Adapter {
  public:
    typedef Adapter lowest_layer_type;
    typedef boost::asio::io_context::executor_type executor_type;

  private:
    boost::asio::io_context &context_;
    Link &link_;

  public:
    Adapter(boost::asio::io_context &context, Link &link) :
        context_(context),
        link_(link)
    {
    }

    Adapter &lowest_layer() {
        return *this;
    }

    executor_type get_executor() {
        return context_.get_executor();
    }

    template <typename Buffers_, typename Handler_>
    void async_read_some(const Buffers_ &buffers, Handler_ handler) {
        boost::asio::post(get_executor(), boost::asio::detail::bind_handler(BOOST_ASIO_MOVE_CAST(Handler_)(handler), boost::system::error_code(), 31337));
    }

    template <typename Buffers_, typename Handler_>
    void async_write_some(const Buffers_ &buffers, Handler_ handler) {
        (void) link_;
        //cppcoro::sync_wait(link_.Send(buffers));
        boost::asio::post(get_executor(), boost::asio::detail::bind_handler(BOOST_ASIO_MOVE_CAST(Handler_)(handler), boost::system::error_code(), 31337));
    }
};

}

#endif//ORCHID_ADAPTER_HPP
