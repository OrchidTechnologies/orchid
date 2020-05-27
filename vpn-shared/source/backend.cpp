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


#include <asio.hpp>

#include "backend.hpp"
#include "baton.hpp"
#include "log.hpp"
#include "shared.hpp"
#include "router.hpp"

namespace orc {

void Backend() {
#if 0
    auto router(Make<Router>());

    (*router)(http::verb::get, R"(^.*$)", [&](Request request) -> task<Response> {
        co_return Respond(request, http::verb::ok, "text/plain", "");
    });

    (*router)(http::verb::unknown, R"(^.*$)", [&](Request request) -> task<Response> {
        co_return Respond(request, http::verb::method_not_allowed, "text/plain", "");
    });

    router->Run(asio::ip::make_address("127.0.0.1"), 8080);
#endif
}

}
