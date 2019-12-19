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


#ifndef ORCHID_DNS_HPP
#define ORCHID_DNS_HPP

#include <vector>

#include <boost/asio/ip/tcp.hpp>

#include <asio.hpp>
#include "shared.hpp"
#include "task.hpp"

namespace orc {

class Origin;

typedef asio::ip::tcp::endpoint Result;
typedef std::vector<Result> Results;

task<Results> Resolve(Origin &origin, const std::string &host, const std::string &port);

}

namespace boost {
namespace asio {
namespace ip {

template <typename Protocol_>
std::ostream &operator <<(std::ostream &out, const std::vector<asio::ip::basic_endpoint<Protocol_>> &endpoints) {
    for (const auto &endpoint : endpoints)
        out << ' ' << endpoint.address().to_string() << ':' << std::dec << endpoint.port();
    return out;
}

template <typename Protocol_>
std::ostream &operator <<(std::ostream &out, const boost::asio::ip::basic_resolver_results<Protocol_> &endpoints) {
    for (const auto &endpoint : endpoints)
        out << ' ' << endpoint.host_name() << ':' << endpoint.service_name();
    return out;
}

} } }

#endif//ORCHID_DNS_HPP
