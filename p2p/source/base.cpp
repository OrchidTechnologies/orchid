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


#include <boost/asio/ssl/rfc2818_verification.hpp>
#include <boost/beast/ssl/ssl_stream.hpp>
#include <boost/beast/version.hpp>

#include <p2p/base/basic_packet_socket_factory.h>
#include <p2p/client/basic_port_allocator.h>
#include <rtc_base/network.h>

#include "adapter.hpp"
#include "base.hpp"
#include "baton.hpp"
#include "beast.hpp"
#include "locator.hpp"
#include "pirate.hpp"

namespace orc {

Base::Base(const char *type, U<rtc::NetworkManager> manager) :
    Valve(type),
    manager_(std::move(manager)),
    cache_(*this)
{
}

Base::~Base() = default;

struct Thread_ { typedef rtc::Thread *(rtc::BasicPacketSocketFactory::*type); };
template struct Pirate<Thread_, &rtc::BasicPacketSocketFactory::thread_>;

U<cricket::PortAllocator> Base::Allocator() {
    auto &factory(Factory());
    const auto thread(factory.*Loot<Thread_>::pointer);
    return thread->Invoke<U<cricket::PortAllocator>>(RTC_FROM_HERE, [&]() {
        return std::make_unique<cricket::BasicPortAllocator>(manager_.get(), &factory);
    });
}

task<Response> Base::Fetch(const std::string &method, const Locator &locator, const std::map<std::string, std::string> &headers, const std::string &data, const std::function<bool (const std::list<const rtc::OpenSSLCertificate> &)> &verify) { orc_ahead orc_block({
    http::request<http::string_body> req(http::string_to_verb(method), locator.path_, 11);
    req.set(http::field::host, locator.origin_.host_);
    req.set(http::field::user_agent, BOOST_BEAST_VERSION_STRING);

    for (auto &[name, value] : headers)
        req.set(name, value);

    req.set(http::field::content_length, std::to_string(data.size()));
    req.body() = data;

    for (;;) {
        // XXX: if I ever have multiple threads I need to lock this
        const auto range(fetchers_.equal_range(locator.origin_));
        if (range.first != range.second) try {
            auto fetcher(std::move(range.first->second));
            fetchers_.erase(range.first);
            auto response(co_await fetcher->Fetch(req));
            fetchers_.emplace(locator.origin_, std::move(fetcher));
            co_return response;
        } catch (...) {
        } else break;
    }

    const auto endpoints(co_await Resolve(locator.origin_.host_, locator.origin_.port_));
    std::exception_ptr error;
    for (const auto &endpoint : endpoints) try {
        auto fetcher(co_await [&]() -> task<U<Fetcher>> {
            Adapter adapter(Context(), co_await Connect(endpoint));

            if (false) {
            } else if (locator.origin_.scheme_ == "http") {
                co_return std::make_unique<Beast<Adapter>>(std::move(adapter));
            } else if (locator.origin_.scheme_ == "https") {
                // XXX: this needs security
                asio::ssl::context context{asio::ssl::context::sslv23_client};

                if (!verify)
                    context.set_verify_callback(asio::ssl::rfc2818_verification(locator.origin_.host_));
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

                boost::beast::ssl_stream<Adapter> stream{std::move(adapter), context};
                orc_assert(SSL_set_tlsext_host_name(stream.native_handle(), locator.origin_.host_.c_str()));
                // XXX: beast::error_code ec{static_cast<int>(::ERR_get_error()), net::error::get_ssl_category()};

                orc_block({ try {
                    co_await stream.async_handshake(asio::ssl::stream_base::client, orc::Adapt());
                } catch (const asio::system_error &error) {
                    orc_adapt(error);
                } }, "in ssl handshake");

                co_return std::make_unique<Beast<boost::beast::ssl_stream<Adapter>>>(std::move(stream));
            } else orc_assert(false);
        }());

        auto response(co_await orc_value(co_return co_await, fetcher->Fetch(req), "connected to " << endpoint));
        // XXX: potentially allow this to be passed in as a custom response validator
        orc_assert_(response.result() != boost::beast::http::status::bad_gateway, response);
        // XXX: if verify were somehow part of origin we could pool this connection
        if (!verify)
            fetchers_.emplace(locator.origin_, std::move(fetcher));
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
