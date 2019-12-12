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


#include <regex>

#include "adapter.hpp"
#include "baton.hpp"
#include "dns.hpp"
#include "error.hpp"
#include "http.hpp"
#include "json.hpp"
#include "locator.hpp"
#include "origin.hpp"
#include "trace.hpp"

namespace orc {

task<Results> Resolve(Origin &origin, const std::string &host, const std::string &port) {
    asio::ip::tcp::resolver resolver(orc::Context());

    Results results;

    static std::regex re("[0-9.]+");
    if (std::regex_match(host, re)) {
        const auto endpoints(co_await resolver.async_resolve(host, port, orc::Token()));
        for (auto &endpoint : endpoints)
            results.emplace_back(endpoint);
    } else {
        const auto result(Parse((co_await origin.Request("GET", {"https", "1.0.0.1", "443", "/dns-query?type=A&name=" + host}, {
            {"accept", "application/dns-json"}
        }, {})).ok()));

        for (const auto &answer : result["Answer"])
            if (answer["type"].asUInt64() == 1) {
                const auto endpoints(co_await resolver.async_resolve(answer["data"].asString(), port, orc::Token()));
                for (const auto &endpoint : endpoints)
                    results.emplace_back(endpoint);
            }
    }

    co_return results;
}

}
