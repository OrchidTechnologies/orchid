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
#include "beast.hpp"
#include "log.hpp"
#include "shared.hpp"
#include "trace.hpp"

namespace http = _0xdead4ead::http;

namespace orc {

void Backend() {
    auto router(Make<http::basic_router<HttpSession>>(std::regex::ECMAScript));

    router->all(R"(^.*$)", [&](auto request, auto context) {
        Respond(context, request, "text/plain", "");
    });

    const auto fail([](auto code, auto from) {
        Log() << "ERROR " << code << " " << from << std::endl;
    });

    HttpListener::launch(Context(), {
        asio::ip::make_address("127.0.0.1"), 8080
    }, [router = std::move(router), fail](auto socket) {
        HttpSession::recv(std::move(socket), *router, fail);
    }, fail);
}

}
