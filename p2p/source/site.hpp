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


#ifndef ORCHID_SITE_HPP
#define ORCHID_SITE_HPP

#include <functional>
#include <list>
#include <string>

#include <boost/beast/http/write.hpp>
#include <boost/beast/version.hpp>

#include "ctre.hpp"
#include "response.hpp"
#include "socket.hpp"
#include "task.hpp"

namespace orc {

using namespace ctre::literals;
typedef ctre::regex_results<const char *> Matches0;
typedef ctre::regex_results<const char *, ctre::captured_content<1>> Matches1;
typedef ctre::regex_results<const char *, ctre::captured_content<1>, ctre::captured_content<2>> Matches2;
typedef ctre::regex_results<const char *, ctre::captured_content<1>, ctre::captured_content<2>, ctre::captured_content<3>> Matches3;

const char *Params();

struct Request : http::request<http::string_body> {
    Socket socket_;

    Request(Socket socket) :
        socket_(std::move(socket))
    {
    }
};

inline std::ostream &operator <<(std::ostream &out, const Request &request) {
    return out << static_cast<const http::request<http::string_body> &>(request);
}

class Site {
  private:
    std::list<std::function<task<Response> (Request &)>> routes_;

    template <bool Expires_, typename Stream_>
    task<bool> Handle(Stream_ &stream, const Socket &socket);

  public:
    void Run(const asio::ip::address &bind, uint16_t port, const std::string &key, const std::string &certificates, const std::string &params = Params());

#ifndef _WIN32
    void Run(const std::string &path);
#endif

    void operator ()(http::verb verb, std::string path, std::function<task<Response> (Request)> code) {
        routes_.emplace_back([verb, path = std::move(path), code = std::move(code)](Request &request) -> task<Response> {
            if (verb != http::verb::unknown && verb != request.method())
                return nullptr;
            if (request.target() != path)
                return nullptr;
            return code(std::move(request));
        });
    }

    template <typename Path_>
    void operator ()(http::verb verb, ctre::regular_expression<Path_> path, std::function<task<Response> (decltype(path.match("")), Request)> code) {
        routes_.emplace_back([verb, path = std::move(path), code = std::move(code)](Request &request) -> task<Response> {
            if (verb != http::verb::unknown && verb != request.method())
                return nullptr;
            auto matches(path.match(request.target()));
            if (!matches)
                return nullptr;
            return code(std::move(matches), std::move(request));
        });
    }
};

Response Respond(const Request &request, http::status status, const std::map<std::string, std::string> &headers, std::string body);

}

#endif//ORCHID_SITE_HPP
