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
#include "query.hpp"

namespace orc {

// XXX: cppcoro shared_task m_next field uninitialized (false positive)
// NOLINTNEXTLINE(clang-analyzer-optin.cplusplus.UninitializedObject)
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
        const auto number(To<uint16_t>(port));
        for (const auto &result : co_await cache_(host))
            results.emplace_back(Socket(result, number));
    }

    co_return std::move(results);
}, "resolving " << host << ":" << port); }

cppcoro::shared_task<Hosts> Base::Resolve_(Base &base, std::string host) {
    if (host == "one.one.one.one")
        co_return Hosts{"1.0.0.1"};

    dns_question_t question{(host += ".").c_str(), RR_A, CLASS_IN};

    dns_query_t query{
        .id = 0x0000,
        .query = true,
        .opcode = OP_QUERY,

        .aa = false,
        .tc = false,
        .rd = true,
        .ra = false,

        .z = false,

        .ad = false,
        .cd = false,

        .rcode = RCODE_OKAY,

        .qdcount = 1,
        .ancount = 0,
        .nscount = 0,
        .arcount = 0,

        .questions = &question,
        .answers = nullptr,
        .nameservers = nullptr,
        .additional = nullptr,
    };

    dns_packet_t packet[DNS_BUFFER_UDP];
    size_t size(sizeof(packet));
    orc_assert(dns_encode(packet, &size, &query) == RCODE_OKAY);

    const Query result((co_await base.Fetch("POST", {{"https", "one.one.one.one", "443"}, "/dns-query"}, {
        {"accept", "application/dns-message"},
        {"content-type", "application/dns-message"},
    }, std::string(reinterpret_cast<const char *>(packet), size))).ok());

    orc_assert_(result->rcode == RCODE_OKAY, dns_rcode_text(result->rcode));

    Hosts hosts;

    for (size_t i(0); i != result->ancount; ++i) {
        const auto &answer(result->answers[i]);
        if (answer.generic.type != RR_A) continue;
        orc_assert(answer.generic.dclass == CLASS_IN);
        hosts.emplace_back(boost::endian::big_to_native(answer.a.address));
    }

    co_return std::move(hosts);
}

}
