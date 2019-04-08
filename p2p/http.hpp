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


#ifndef ORCHID_HTTP_HPP
#define ORCHID_HTTP_HPP

#include <map>
#include <string>

#include <cppcoro/task.hpp>

#include "link.hpp"

namespace orc {

class URI {
  public:
    std::string schema_;
    std::string host_;
    std::string port_;
    std::string path_;

    URI(const std::string &uri);

    URI(std::string schema, std::string host, std::string port, std::string path) :
        schema_(schema),
        host_(host),
        port_(port),
        path_(path)
    {
    }
};

cppcoro::task<std::string> Request(U<Link> link, const std::string &method, const URI &uri, const std::map<std::string, std::string> &headers, const std::string &data);

cppcoro::task<std::string> Request(const std::string &method, const URI &uri, const std::map<std::string, std::string> &headers, const std::string &data);

}

#endif//ORCHID_HTTP_HPP
