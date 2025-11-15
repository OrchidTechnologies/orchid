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


#ifndef ORCHID_LAYER_HPP
#define ORCHID_LAYER_HPP

#include <boost/asio/ssl/host_name_verification.hpp>
#include <boost/beast/ssl/ssl_stream.hpp>

#include "adapter.hpp"
#include "base.hpp"
#include "baton.hpp"

namespace orc {

template <template<typename> class Type_, typename Code_>
auto Layer(Base &base, const Locator &locator, const std::function<bool (const std::list<rtc::OpenSSLCertificate> &)> &verify, Code_ code) -> decltype(std::declval<Code_>()(nullptr)) {
    const auto endpoints(co_await base.Resolve(locator.origin_.host_, locator.origin_.port_));
    std::exception_ptr error;
    for (const auto &endpoint : endpoints) try { orc_block({
        Adapter adapter(Context(), co_await base.Connect(endpoint));

        if (false) {
        } else if (locator.origin_.scheme_ == "http") {
            co_return co_await std::move(code)(std::make_unique<Type_<Adapter>>(std::move(adapter)));
        } else if (locator.origin_.scheme_ == "https" || locator.origin_.scheme_ == "wss") {
            // XXX: this needs security
            asio::ssl::context context(asio::ssl::context::sslv23_client);

            if (!verify)
                context.set_verify_callback(asio::ssl::host_name_verification(locator.origin_.host_));
            else {
                context.set_verify_mode(asio::ssl::verify_peer);

                context.set_verify_callback([&](bool preverified, boost::asio::ssl::verify_context &context) {
                    const auto store(context.native_handle());
                    const auto chain(X509_STORE_CTX_get0_chain(store));
                    std::list<rtc::OpenSSLCertificate> certificates;
                    for (auto e(sk_X509_num(chain)), i(decltype(e)(0)); i != e; i++)
                        certificates.emplace_back(sk_X509_value(chain, i));
                    return verify(certificates);
                });
            }

            boost::beast::ssl_stream<Adapter> stream(std::move(adapter), context);
            orc_assert(SSL_set_tlsext_host_name(stream.native_handle(), locator.origin_.host_.c_str()));
            // XXX: beast::error_code ec{static_cast<int>(::ERR_get_error()), net::error::get_ssl_category()};

            orc_block({ try {
                co_await stream.async_handshake(asio::ssl::stream_base::client, orc::Adapt());
            } catch (const asio::system_error &error) {
                orc_adapt(error);
            } }, "in ssl handshake");

            co_return co_await std::move(code)(std::make_unique<Type_<boost::beast::ssl_stream<Adapter>>>(std::move(stream)));
        } else orc_assert(false);
    }, "using endpoint " << endpoint); } catch (...) {
        // XXX: maybe I should merge the exceptions? that would be cool
        if (error == nullptr)
            error = std::current_exception();
    }

    orc_assert_(error != nullptr, "failed connection");
    std::rethrow_exception(error);
}

}

#endif//ORCHID_LAYER_HPP
