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


#include "dns.hpp"
#include "duplex.hpp"

namespace orc {

Duplex::Duplex(S<Origin> origin) :
    origin_(std::move(origin)),
    inner_(Context())
{
}

task<size_t> Duplex::Read(Beam &beam) {
    size_t writ;
    try {
        boost::beast::buffers_adaptor buffer(asio::buffer(beam.data(), beam.size()));
        writ = co_await inner_.async_read(buffer, Token());
    } catch (const asio::system_error &error) {
        auto code(error.code());
        if (code == asio::error::eof)
            co_return 0;
        orc_adapt(error);
    }

    co_return writ;
}

task<boost::asio::ip::tcp::endpoint> Duplex::Open(const Locator &locator) { orc_block({
    const auto endpoints(co_await Resolve(*origin_, locator.host_, locator.port_));
    auto &lowest(boost::beast::get_lowest_layer(inner_));
    const auto endpoint(co_await orc_value(co_return co_await, lowest.async_connect(endpoints, Token()),
        "connecting to" << endpoints));
    lowest.expires_never();
    co_await inner_.async_handshake(locator.host_, locator.path_, Token());
    co_return endpoint;
}, "opening " << locator); }

task<void> Duplex::Shut() noexcept {
    try {
        co_await inner_.async_close(boost::beast::websocket::close_code::normal, Token());
    } catch (const asio::system_error &error) {
        orc_except({ orc_adapt(error); })
    }
}

task<void> Duplex::Send(const Buffer &data) {
    const size_t writ(co_await [&]() -> task<size_t> { try {
        co_return co_await inner_.async_write(Sequence(data), Token());
    } catch (const asio::system_error &error) {
        orc_adapt(error);
    } }());
    orc_assert_(writ == data.size(), "orc_assert(" << writ << " {writ} == " << data.size() << " {data.size()})");
}

}
