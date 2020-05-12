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


#ifndef ORCHID_ROUTER_HPP
#define ORCHID_ROUTER_HPP

#include <functional>
#include <list>
#include <regex>
#include <string>

#include <boost/beast/version.hpp>

#include "response.hpp"
#include "task.hpp"

namespace orc {

const char *Params();

typedef http::request<http::string_body> Request;

class Router {
  private:
    std::list<std::tuple<http::verb, std::regex, std::function<task<Response> (Request)>>> routes_;

  public:
    void Run(const asio::ip::address &bind, uint16_t port, const std::string &key, const std::string &chain, const std::string &params = Params());

    void operator()(http::verb verb, const std::string &path, std::function<task<Response> (Request)> code) {
        routes_.emplace_back(verb, path, std::move(code));
    }
};

Response Respond(const Request &request, http::status status, const std::string &type, std::string body);

}

#endif//ORCHID_ROUTER_HPP
