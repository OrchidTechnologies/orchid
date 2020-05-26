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

#include "adapter.hpp"
#include "baton.hpp"
#include "dns.hpp"
#include "error.hpp"
#include "http.hpp"
#include "local.hpp"
#include "locator.hpp"

namespace orc {

template <typename Stream_>
task<Response> Fetch_(Stream_ &stream, http::request<http::string_body> &req) { orc_ahead
    orc_block({ (void) co_await http::async_write(stream, req, orc::Token()); },
        "writing http request");

    // this buffer must be maintained if this socket object is ever reused
    boost::beast::flat_buffer buffer;
    http::response<http::dynamic_body> res;
    orc_block({ (void) co_await http::async_read(stream, buffer, res, orc::Token()); },
        "reading http response");

    // XXX: I can probably return this as a buffer array
    Response response(res.result(), req.version());;
    response.body() = boost::beast::buffers_to_string(res.body().data());
    co_return response;
}

template <typename Socket_>
task<Response> Fetch_(Socket_ &socket, const std::string &method, const Locator &locator, const std::map<std::string, std::string> &headers, const std::string &data, const std::function<bool (const std::list<const rtc::OpenSSLCertificate> &)> &verify) { orc_ahead
    http::request<http::string_body> req{http::string_to_verb(method), locator.path_, 11};
    req.set(http::field::host, locator.host_);
    req.set(http::field::user_agent, BOOST_BEAST_VERSION_STRING);

    for (auto &[name, value] : headers)
        req.set(name, value);

    req.set(http::field::content_length, data.size());
    req.body() = data;

    if (false) {
    } else if (locator.scheme_ == "http") {
        co_return co_await Fetch_(socket, req);
    } else if (locator.scheme_ == "https") {
        // XXX: this needs security
        asio::ssl::context context{asio::ssl::context::sslv23_client};

        if (!verify)
            context.set_verify_callback(asio::ssl::rfc2818_verification(locator.host_));
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
        orc_assert(SSL_set_tlsext_host_name(stream.native_handle(), locator.host_.c_str()));
        // XXX: beast::error_code ec{static_cast<int>(::ERR_get_error()), net::error::get_ssl_category()};

        orc_block({ try {
            co_await stream.async_handshake(asio::ssl::stream_base::client, orc::Token());
        } catch (const asio::system_error &error) {
            orc_adapt(error);
        } }, "in ssl handshake");

        const auto response(co_await Fetch_(stream, req));

        orc_block({ try {
            co_await stream.async_shutdown(orc::Token());
        } catch (const asio::system_error &error) {
            auto code(error.code());
            if (false);
            else if (code == asio::error::eof);
                // XXX: this scenario is untested
            else if (code == asio::ssl::error::stream_truncated);
                // XXX: this is because of infura
            else orc_adapt(error);
        } }, "in ssl shutdown");

        co_return response;
    } else orc_assert(false);
}

task<Response> Fetch(Origin &origin, const std::string &method, const Locator &locator, const std::map<std::string, std::string> &headers, const std::string &data, const std::function<bool (const std::list<const rtc::OpenSSLCertificate> &)> &verify) { orc_ahead orc_block({
    const auto endpoints(co_await Resolve(origin, locator.host_, locator.port_));
    std::exception_ptr error;
    for (const auto &endpoint : endpoints) try {
        Adapter adapter(Context(), co_await orc_value(co_return co_await, origin.Connect(endpoint), "connecting to " << endpoint));
        const auto response(co_await orc_value(co_return co_await, Fetch_(adapter, method, locator, headers, data, verify), "connected to " << endpoint));
        // XXX: potentially allow this to be passed in as a custom response validator
        orc_assert_(response.result() != boost::beast::http::status::bad_gateway, response);
        co_return response;
    } catch (...) {
        // XXX: maybe I should merge the exceptions? that would be cool
        if (error == nullptr)
            error = std::current_exception();
    }
    orc_assert_(error != nullptr, "failed connection");
    std::rethrow_exception(error);
}, "requesting " << locator); }

}
