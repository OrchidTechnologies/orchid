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


#ifndef ORCHID_BEAST_HPP
#define ORCHID_BEAST_HPP

#include <boost/beast/core/buffers_to_string.hpp>
#include <boost/beast/core/flat_buffer.hpp>

#include <boost/beast/http/dynamic_body.hpp>
#include <boost/beast/http/read.hpp>
#include <boost/beast/http/write.hpp>

#include "fetcher.hpp"

namespace orc {

template <typename Stream_>
class Beast :
    public Fetcher
{
  private:
    Stream_ stream_;
    boost::beast::flat_buffer buffer_;

  public:
    Beast(Stream_ stream) :
        stream_(std::move(stream))
    {
    }

    task<Response> Fetch(http::request<http::string_body> &req) override;
};

template <typename Stream_>
task<Response> Beast<Stream_>::Fetch(http::request<http::string_body> &req) { orc_ahead
    orc_block({ (void) co_await http::async_write(stream_, req, orc::Adapt()); },
        "writing http request");

    http::response<http::dynamic_body> res;
    orc_block({ (void) co_await http::async_read(stream_, buffer_, res, orc::Adapt()); },
        "reading http response");

    // XXX: I can probably return this as a buffer array
    Response response(res.result(), req.version());;
    response.body() = boost::beast::buffers_to_string(res.body().data());
    co_return response;
}

}

#endif//ORCHID_BEAST_HPP
