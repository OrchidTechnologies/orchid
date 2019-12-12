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


#include "baton.hpp"
#include "beast.hpp"
#include "node.hpp"

namespace orc {

void Node::Run(const asio::ip::address &bind, uint16_t port, const std::string &path, const std::string &key, const std::string &chain, const std::string &params) {
    boost::asio::ssl::context context{boost::asio::ssl::context::tlsv12};

    context.set_options(
        boost::asio::ssl::context::default_workarounds |
        boost::asio::ssl::context::no_sslv2 |
        boost::asio::ssl::context::single_dh_use |
    0);

    context.use_certificate_chain(boost::asio::buffer(chain.data(), chain.size()));
    context.use_private_key(boost::asio::buffer(key.data(), key.size()), boost::asio::ssl::context::file_format::pem);
    context.use_tmp_dh(boost::asio::buffer(params.data(), params.size()));


    http::basic_router<SslHttpSession> router{std::regex::ECMAScript};

    router.post(path, [&](auto request, auto context) {
        Log() << request << std::endl;

        try {
            auto body(request.body());
            static int fingerprint_(0);
            std::string fingerprint(std::to_string(fingerprint_++));
            auto server(Find(fingerprint));

            auto offer(body);
            auto answer(Wait(server->Respond(offer, ice_)));

            Log() << std::endl;
            Log() << "^^^^^^^^^^^^^^^^" << std::endl;
            Log() << offer << std::endl;
            Log() << "================" << std::endl;
            Log() << answer << std::endl;
            Log() << "vvvvvvvvvvvvvvvv" << std::endl;
            Log() << std::endl;

            Respond(context, request, "text/plain", answer);
        } catch (...) {
            Respond(context, request, "text/plain", "", boost::beast::http::status::not_found);
        }
    });

    router.all(R"(^.*$)", [&](auto request, auto context) {
        Log() << request << std::endl;
        Respond(context, request, "text/plain", "");
    });

    auto fail([](auto code, auto from) {
        Log() << "ERROR " << code << " " << from << std::endl;
    });

    HttpListener::launch(Context(), {bind, port}, [&](auto socket) {
        SslHttpSession::handshake(context, std::move(socket), router, [](auto context) {
            context.recv();
        }, fail);
    }, fail);

    Thread().join();
}

}
