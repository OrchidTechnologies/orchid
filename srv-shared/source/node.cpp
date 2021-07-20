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


#include "baton.hpp"
#include "node.hpp"
#include "site.hpp"
#include "version.hpp"

namespace orc {

void Node::Run(const asio::ip::address &bind, uint16_t port, const std::string &key, const std::string &certificates, const std::string &params) {
    Site site;

    site(http::verb::post, "/", [&](Request request) -> task<Response> {
        const auto offer(request.body());
        // XXX: look up fingerprint
        static int fingerprint_(0);
        std::string fingerprint(std::to_string(fingerprint_++));
        const auto server(Find(fingerprint));
        auto answer(co_await server->Respond(base_, offer, ice_));

        if (Verbose) {
            Log() << std::endl;
            Log() << "^^^^^^^^^^^^^^^^" << std::endl;
            Log() << offer << std::endl;
            Log() << "================" << std::endl;
            Log() << answer << std::endl;
            Log() << "vvvvvvvvvvvvvvvv" << std::endl;
            Log() << std::endl;
        }

        co_return Respond(request, http::status::ok, {
            {"content-type", "text/plain"},
        }, std::move(answer));
    });

    site(http::verb::get, "/version.txt", [&](Request request) -> task<Response> {
        co_return Respond(request, http::status::ok, {
            {"content-type", "text/plain"},
        }, std::string(VersionData, VersionSize));
    });

    site.Run(bind, port, key, certificates, params);
    Thread().join();
}

}
