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


#ifndef ORCHID_RESPONSE_HPP
#define ORCHID_RESPONSE_HPP

#include <map>
#include <string>

#include <boost/beast/http/message.hpp>
#include <boost/beast/http/status.hpp>
#include <boost/beast/http/string_body.hpp>

#include "error.hpp"

namespace orc {

namespace http = boost::beast::http;

struct Response;

std::ostream &operator <<(std::ostream &out, const Response &response);

struct Response :
    public http::response<http::string_body>
{
    using http::response<http::string_body>::response;

    Response(const Response &response) = delete;
    Response(Response &&response) = default;

    Response(http::response<http::string_body> &&response) :
        http::response<http::string_body>(response)
    {
    }

    std::string on(bool check) && {
        orc_assert_(check, *this);
        return std::move(body());
    }

    std::string is(http::status status) && {
        return std::move(*this).on(result() == status);
    }

    std::string is(http::status_class status) && {
        return std::move(*this).on(to_status_class(result()) == status);
    }

    std::string ok() && {
        return std::move(*this).is(http::status::ok);
    }

    std::string operator ()() && {
        return std::move(*this).is(http::status_class::successful);
    }
};

inline std::ostream &operator <<(std::ostream &out, const Response &response) {
    out << "{ status: " << response.result() << ", body: ```" << response.body() << "``` }";
    for (const auto &header : response)
        out << "  " << header.name_string() << ":" << header.value() << std::endl;
    return out;
}

}

#endif//ORCHID_RESPONSE_HPP
