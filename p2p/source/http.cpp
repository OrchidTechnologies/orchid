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
#include <boost/asio/ssl/rfc2818_verification.hpp>
#include <boost/asio/ssl/stream.hpp>

#include <asio/co_spawn.hpp>
#include <asio/detached.hpp>

//#include "adapter.hpp"
#include "baton.hpp"
#include "dns.hpp"
#include "error.hpp"
#include "http.hpp"
#include "local.hpp"
#include "locator.hpp"
#include "trace.hpp"

namespace orc {

template <typename Stream_>
task<Response> Request_(Stream_ &stream, boost::beast::http::request<boost::beast::http::string_body> &req) {
    (void) co_await boost::beast::http::async_write(stream, req, orc::Token());

    // this buffer must be maintained if this socket object is ever reused
    boost::beast::flat_buffer buffer;
    boost::beast::http::response<boost::beast::http::dynamic_body> res;
    (void) co_await boost::beast::http::async_read(stream, buffer, res, orc::Token());

    // XXX: I can probably return this as a buffer array
    co_return Response{res.result(), boost::beast::buffers_to_string(res.body().data())};
}

template <typename Socket_>
task<Response> Request_(Socket_ &socket, const std::string &method, const Locator &locator, const std::map<std::string, std::string> &headers, const std::string &data, const std::function<bool (const std::list<const rtc::OpenSSLCertificate> &)> &verify) {
    boost::beast::http::request<boost::beast::http::string_body> req{boost::beast::http::string_to_verb(method), locator.path_, 11};
    req.set(boost::beast::http::field::host, locator.host_);
    req.set(boost::beast::http::field::user_agent, BOOST_BEAST_VERSION_STRING);

    for (auto &[name, value] : headers)
        req.set(name, value);

    req.set(boost::beast::http::field::content_length, data.size());
    req.body() = data;

    if (false) {
    } else if (locator.scheme_ == "http") {
        co_return co_await Request_(socket, req);
    } else if (locator.scheme_ == "https") {
        // XXX: this needs security
        asio::ssl::context context{asio::ssl::context::sslv23_client};

        if (!verify)
            // XXX: verification did not work against infura
            /*context.set_verify_callback(asio::ssl::rfc2818_verification(locator.host_))*/;
        else {
            context.set_verify_mode(asio::ssl::verify_peer);

            context.set_verify_callback([&](bool preverified, boost::asio::ssl::verify_context &context) {
                const auto store(context.native_handle());
                const auto chain(X509_STORE_CTX_get0_chain(store));
                std::list<const rtc::OpenSSLCertificate> certificates;
                for (auto e(sk_X509_num(chain)), i(decltype(e)(0)); i != e; i++)
                    certificates.emplace_back(sk_X509_value(chain, i));
                return verify(certificates);
            });
        }

        asio::ssl::stream<Socket_ &> stream{socket, context};

        try {
            co_await stream.async_handshake(asio::ssl::stream_base::client, orc::Token());
        } catch (const asio::system_error &error) {
            orc_adapt(error);
        }

        const auto response(co_await Request_(stream, req));

        try {
            co_await stream.async_shutdown(orc::Token());
        } catch (const asio::system_error &error) {
            auto code(error.code());
            if (false);
            else if (code == asio::error::eof);
                // XXX: this scenario is untested
            else if (code == asio::ssl::error::stream_truncated);
                // XXX: this is because of infura
            else orc_adapt(error);
        }

        co_return response;
    } else orc_assert(false);
}

#if 0
task<Response> Request(Adapter &adapter, const std::string &method, const Locator &locator, const std::map<std::string, std::string> &headers, const std::string &data, const std::function<bool (const rtc::OpenSSLCertificate &)> &verify) {
    return Request_(adapter, method, locator, headers, data, verify);
}
#endif

task<Response> Request(const std::string &method, const Locator &locator, const std::map<std::string, std::string> &headers, const std::string &data, const std::function<bool (const std::list<const rtc::OpenSSLCertificate> &)> &verify) {
    // XXX: implement remote http requests
    const auto local(Break<Local>());
    const auto results(co_await Resolve(*local, locator.host_, locator.port_));
    asio::ip::tcp::socket socket(orc::Context());
    (void) co_await asio::async_connect(socket, results.begin(), results.end(), orc::Token());

    const auto body(co_await Request_(socket, method, locator, headers, data, verify));

    boost::beast::error_code error;
    socket.shutdown(asio::ip::tcp::socket::shutdown_both, error);
    if (error && error != boost::beast::errc::not_connected)
        throw boost::beast::system_error{error};

    co_return body;
}

}
