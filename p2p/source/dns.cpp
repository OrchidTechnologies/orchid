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


#include <regex>

#include <dns.h>
#include <mappings.h>

#include "base.hpp"
#include "baton.hpp"
#include "dns.hpp"
#include "error.hpp"
#include "locator.hpp"
#include "notation.hpp"

namespace orc {

task<std::vector<asio::ip::tcp::endpoint>> Base::Resolve(const std::string &host, const std::string &port) { orc_block({
    if (host == "localhost")
        co_return co_await Resolve("127.0.0.1", port);

    asio::ip::tcp::resolver resolver(orc::Context());

    std::vector<asio::ip::tcp::endpoint> results;

    static const std::regex re("[0-9.]+");
    if (std::regex_match(host, re)) {
        const auto endpoints(resolver.resolve(host, port));
        for (auto &endpoint : endpoints)
            results.emplace_back(endpoint);
    } else {
        const auto &result(co_await cache_(host));
        const auto status(static_cast<dns_rcode_t>(Num<uint16_t>(result.at("Status"))));
        orc_assert_(status == RCODE_OKAY, dns_rcode_text(status));

        for (const auto &answer : result.at("Answer").as_array())
            if (static_cast<dns_type>(Num<uint16_t>(answer.at("type"))) == RR_A) {
                const auto endpoints(resolver.resolve(Str(answer.at("data")), port));
                for (const auto &endpoint : endpoints)
                    results.emplace_back(endpoint);
            }
    }

    co_return std::move(results);
}, "resolving " << host << ":" << port); }

cppcoro::shared_task<Any> Base::Resolve_(Base &base, const std::string &host) {
    co_return Parse((co_await base.Fetch("GET", {{"https", "1.0.0.1", "443"}, "/dns-query?type=A&name=" + host}, {
        {"accept", "application/dns-json"}
    }, {})).ok());
}

}
