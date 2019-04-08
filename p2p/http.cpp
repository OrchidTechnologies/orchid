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


#include <cppcoro/sync_wait.hpp>

#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>
#include <boost/beast/version.hpp>

#include <boost/asio/connect.hpp>
#include <boost/asio/ip/tcp.hpp>

#include <boost/asio/ssl/context.hpp>
#include <boost/asio/ssl/error.hpp>
#include <boost/asio/ssl/stream.hpp>

#include <asio/experimental/co_spawn.hpp>
#include <asio/experimental/detached.hpp>

#include "adapter.hpp"
#include "baton.hpp"
#include "error.hpp"
#include "http.hpp"
#include "trace.hpp"

namespace orc {

template <typename Stream_>
task<std::string> Request(Stream_ &stream, boost::beast::http::request<boost::beast::http::string_body> &req) {
    (void) co_await boost::beast::http::async_write(stream, req, orc::Token());

    boost::beast::flat_buffer buffer;
    boost::beast::http::response<boost::beast::http::dynamic_body> res;
    (void) co_await boost::beast::http::async_read(stream, buffer, res, orc::Token());

    _assert_(res.result() == boost::beast::http::status::ok, res.reason());
    co_return boost::beast::buffers_to_string(res.body().data());
}

template <typename Socket_>
task<std::string> Request(Socket_ &socket, const std::string &method, const URI &uri, const std::map<std::string, std::string> &headers, const std::string &data) {
    boost::beast::http::request<boost::beast::http::string_body> req{boost::beast::http::string_to_verb(method), uri.path_, 11};
    req.set(boost::beast::http::field::host, uri.host_);
    req.set(boost::beast::http::field::user_agent, BOOST_BEAST_VERSION_STRING);

    for (auto &[name, value] : headers)
        req.set(name, value);

    req.set(boost::beast::http::field::content_length, data.size());
    req.body() = data;

    std::string body;

    if (false) {
    } else if (uri.schema_ == "http") {
        body = co_await Request(socket, req);
    } else if (uri.schema_ == "https") {
        // XXX: this needs security
        boost::asio::ssl::context context{boost::asio::ssl::context::sslv23_client};
        context.set_verify_mode(boost::asio::ssl::verify_none);

        boost::asio::ssl::stream<Socket_ &> stream{socket, context};
        co_await stream.async_handshake(boost::asio::ssl::stream_base::client, orc::Token());

        body = co_await Request(stream, req);

        try {
            co_await stream.async_shutdown(orc::Token());
        } catch (const boost::system::error_code &error) {
            if (false);
            else if (error == boost::asio::error::eof);
                // XXX: this scenario is untested
            else if (error == boost::asio::ssl::error::stream_truncated);
                // XXX: this is because of infura
            else throw;
        }
    } else _assert(false);

    co_return body;
}

task<std::string> Request(U<Link> link, const std::string &method, const URI &uri, const std::map<std::string, std::string> &headers, const std::string &data) {
    Adapter adapter(orc::Context(), std::move(link));
    return Request(adapter, method, uri, headers, data);
}

task<std::string> Request(const std::string &method, const URI &uri, const std::map<std::string, std::string> &headers, const std::string &data) {
    boost::asio::ip::tcp::resolver resolver(orc::Context());
    const auto results(co_await resolver.async_resolve(uri.host_, uri.port_, orc::Token()));

    boost::asio::ip::tcp::socket socket(orc::Context());
    (void) co_await boost::asio::async_connect(socket, results.begin(), results.end(), orc::Token());

    auto body(co_await Request(socket, method, uri, headers, data));

    boost::beast::error_code ec;
    socket.shutdown(boost::asio::ip::tcp::socket::shutdown_both, ec);
    if (ec && ec != boost::beast::errc::not_connected)
        throw boost::beast::system_error{ec};

    co_return body;
}

}
