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


#include <asio/ip/tcp.hpp>

#include <boost/beast/core/tcp_stream.hpp>
#include <boost/beast/http.hpp>
#include <boost/beast/ssl.hpp>
#include <boost/beast/version.hpp>
#include <boost/beast/websocket.hpp>

#include "baton.hpp"
#include "router.hpp"
#include "spawn.hpp"
#include "task.hpp"

namespace orc {

namespace beast = boost::beast;

const char *Params() {
    return
        "-----BEGIN DH PARAMETERS-----\n"
        "MIIBCAKCAQEA///////////JD9qiIWjCNMTGYouA3BzRKQJOCIpnzHQCC76mOxOb\n"
        "IlFKCHmONATd75UZs806QxswKwpt8l8UN0/hNW1tUcJF5IW1dmJefsb0TELppjft\n"
        "awv/XLb0Brft7jhr+1qJn6WunyQRfEsf5kkoZlHs5Fs9wgB8uKFjvwWY2kg2HFXT\n"
        "mmkWP6j9JM9fg2VdI9yjrZYcYvNWIIVSu57VKQdwlpZtZww1Tkq8mATxdGwIyhgh\n"
        "fDKQXkYuNs474553LBgOhgObJ4Oi7Aeij7XFXfBvTFLJ3ivL9pVYFxg5lUl86pVq\n"
        "5RXSJhiY+gUQFXKOWoqsqmj//////////wIBAg==\n"
        "-----END DH PARAMETERS-----\n"
    ;
}

template <bool Expires_, typename Stream_>
task<bool> Router::Handle(Stream_ &stream, const Socket &socket) {
    beast::flat_buffer buffer;

    for (;;) {
        Request request(socket);
        try {
            co_await http::async_read(stream, buffer, request, Adapt());
        } catch (const asio::system_error &error) {
            const auto code(error.code());
            if (false);
            else if (code == asio::ssl::error::stream_truncated);
            else if (code == beast::error::timeout);
            else if (code == http::error::end_of_stream);
            else if (code == http::error::partial_message);
            else orc_adapt(error);
            co_return false;
        }

        if (beast::websocket::is_upgrade(request)) {
            if constexpr (Expires_)
                beast::get_lowest_layer(stream).expires_never();
            Log() << request << std::endl;
            beast::websocket::stream<Stream_> ws(std::move(stream));
            ws.set_option(beast::websocket::stream_base::timeout::suggested(beast::role_type::server));
            ws.set_option(beast::websocket::stream_base::decorator([](beast::websocket::response_type &response) {
                response.set(http::field::server, BOOST_BEAST_VERSION_STRING);
            }));
            co_await ws.async_accept(request, Adapt());

            for (;;) {
                const auto writ(co_await ws.async_read(buffer, Adapt()));
                orc_insist(buffer.size() == writ);
                Log() << writ << std::endl;
                ws.text(ws.got_text());
                orc_insist(co_await ws.async_write(buffer.data(), Adapt()) == writ);
                buffer.consume(writ);
            }

            co_return true;
        }

        const auto response(co_await [&]() -> task<Response> { try {
            for (const auto &route : routes_)
                if (auto response = route(request))
                    co_return co_await std::move(response);
            Log() << request << std::endl;
            // XXX: maybe return method_not_allowed if path is found but method is not
            co_return Respond(request, http::status::not_found, "text/plain", "");
        } catch (const std::exception &error) {
            co_return Respond(request, http::status::internal_server_error, "text/plain", error.what());
        } }());

        co_await http::async_write(stream, response, Adapt());
        if (!response.keep_alive())
            break;
    }

    co_return true;
}

void Router::Run(const asio::ip::address &bind, uint16_t port, const std::string &key, const std::string &certificates, const std::string &params) {
    asio::ssl::context ssl{asio::ssl::context::tlsv12};

    ssl.set_options(
        asio::ssl::context::default_workarounds |
        asio::ssl::context::no_sslv2 |
        asio::ssl::context::single_dh_use |
    0);

    ssl.use_certificate_chain(asio::buffer(certificates.data(), certificates.size()));
    ssl.use_private_key(asio::buffer(key.data(), key.size()), asio::ssl::context::file_format::pem);
    ssl.use_tmp_dh(asio::buffer(params.data(), params.size()));

    Spawn([this, bind, port, ssl = std::move(ssl)]() mutable noexcept -> task<void> {
        asio::ip::tcp::acceptor acceptor(Context(), asio::ip::tcp::v4());

#ifdef _WIN32
        acceptor.set_option(asio::detail::socket_option::boolean<SOL_SOCKET, SO_EXCLUSIVEADDRUSE>(true));
#else
        acceptor.set_option(asio::socket_base::reuse_address(true));
#endif
        acceptor.bind(asio::ip::tcp::endpoint(bind, port));

        acceptor.listen();
        acceptor.non_blocking(true);

        for (;;) {
            asio::ip::tcp::socket connection(Context());
            asio::ip::tcp::endpoint endpoint;
            co_await acceptor.async_accept(connection, endpoint, Adapt());
            Spawn([this, connection = std::move(connection), endpoint = std::move(endpoint), &ssl]() mutable noexcept -> task<void> { try {
                beast::ssl_stream<beast::tcp_stream> stream(std::move(connection), ssl);
                beast::get_lowest_layer(stream).expires_after(std::chrono::seconds(30));

                co_await stream.async_handshake(asio::ssl::stream_base::server, Adapt());
                if (co_await Handle<true>(stream, endpoint)) try {
                    co_await stream.async_shutdown(Adapt());
                } catch (const asio::system_error &error) {
                    // XXX: SSL_OP_IGNORE_UNEXPECTED_EOF ?
                    //const auto code(error.code());
                    if (false);
                    //else if (code == asio::ssl::error::stream_truncated);
                    else orc_adapt(error);
                }
            } orc_catch({}) }, "Router::handle");
        }
    }, "Router::accept");
}

#ifndef _WIN32
void Router::Run(const std::string &path) {
    Spawn([this, path]() noexcept -> task<void> {
        unlink(path.c_str());
        asio::local::stream_protocol::acceptor acceptor(Context(), path);

        acceptor.listen();
        acceptor.non_blocking(true);

        for (;;) {
            asio::local::stream_protocol::socket connection(Context());
            co_await acceptor.async_accept(connection, Adapt());
            Spawn([this, connection = std::move(connection)]() mutable noexcept -> task<void> {
                co_await Handle<false>(connection, Socket());
            }, "Router::handle");
        }
    }, "Router::accept");
}
#endif

Response Respond(const Request &request, http::status status, const std::string &type, std::string body) {
    auto const size(body.size());

    Response response{std::piecewise_construct,
        std::make_tuple(std::move(body)),
        std::make_tuple(status, request.version())
    };

    response.set(http::field::server, BOOST_BEAST_VERSION_STRING);
    response.set(http::field::content_type, type);

    response.content_length(size);
    response.keep_alive(request.keep_alive());

    return response;
}

}
