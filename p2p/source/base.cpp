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


#include <boost/beast/version.hpp>

#include <p2p/base/basic_packet_socket_factory.h>
#include <p2p/client/basic_port_allocator.h>
#include <rtc_base/network.h>

#include "adapter.hpp"
#include "base.hpp"
#include "baton.hpp"
#include "beast.hpp"
#include "layer.hpp"
#include "locator.hpp"
#include "pirate.hpp"
#include "threads.hpp"

namespace orc {

Base::Base(const char *type, U<rtc::NetworkManager> manager) :
    Valve(type),
    manager_(std::move(manager)),
    cache_(*this)
{
}

Base::~Base() = default;

U<cricket::PortAllocator> Base::Allocator() {
    auto &factory(Factory());
    // XXX: should this really block?
    return Wait(Post([&]() -> U<cricket::PortAllocator> {
        return std::make_unique<cricket::BasicPortAllocator>(manager_.get(), &factory);
    }, Thread()));
}

task<Response> Base::Fetch(const std::string &method, const Locator &locator, const std::map<std::string, std::string> &headers, const std::string &data, const std::function<bool (const std::list<const rtc::OpenSSLCertificate> &)> &verify) { orc_ahead orc_block({
    http::request<http::string_body> request(http::string_to_verb(method), locator.path_, 11);
    request.set(http::field::host, locator.origin_.host_);
    request.set(http::field::user_agent, BOOST_BEAST_VERSION_STRING);
    request.set(http::field::connection, "keep-alive");

    for (auto &[name, value] : headers)
        request.set(name, value);

    request.set(http::field::content_length, std::to_string(data.size()));
    request.body() = data;

    for (;;) {
        // XXX: if I ever have multiple threads I need to lock this
        const auto range(fetchers_.equal_range(locator.origin_));
        if (range.first != range.second) try {
            auto fetcher(std::move(range.first->second));
            fetchers_.erase(range.first);
            auto response(co_await fetcher->Fetch(request));
            fetchers_.emplace(locator.origin_, std::move(fetcher));
            co_return response;
        } catch (...) {
        } else break;
    }

    co_return co_await Layer<Beast>(*this, locator, verify, [&](U<Fetcher> fetcher) -> task<Response> {
        auto response(co_await fetcher->Fetch(request));
        // XXX: potentially allow this to be passed in as a custom response validator
        orc_assert_(response.result() != boost::beast::http::status::bad_gateway, response);
        // XXX: if verify were somehow part of origin we could pool this connection
        if (!verify)
            fetchers_.emplace(locator.origin_, std::move(fetcher));
        co_return response;
    });
}, "requesting " << locator); }

}
