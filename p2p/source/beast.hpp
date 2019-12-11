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


#ifndef ORCHID_BEAST_HPP
#define ORCHID_BEAST_HPP

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable"
#include <http/basic_router.hxx>
#include <http/out.hxx>
#include <http/reactor/listener.hxx>
#include <http/reactor/session.hxx>
#include <http/reactor/ssl/session.hxx>
#pragma clang diagnostic pop

namespace http = _0xdead4ead::http;

namespace orc {

using HttpSession = http::reactor::_default::session_type;
using HttpListener = http::reactor::_default::listener_type;
using SslHttpSession = http::reactor::ssl::_default::session_type;

template<typename Context_, typename Body_>
void Respond(Context_ &context, const boost::beast::http::request<Body_> &request, const std::string &type, typename Body_::value_type body, boost::beast::http::status status = boost::beast::http::status::ok) {
    auto const size(body.size());

    boost::beast::http::response<Body_> response{std::piecewise_construct,
        std::make_tuple(std::move(body)),
        std::make_tuple(status, request.version())
    };

    response.set(boost::beast::http::field::server, BOOST_BEAST_VERSION_STRING);
    response.set(boost::beast::http::field::content_type, type);

    response.content_length(size);
    response.keep_alive(request.keep_alive());

    context.send(response);
}

}

#endif//ORCHID_BEAST_HPP
