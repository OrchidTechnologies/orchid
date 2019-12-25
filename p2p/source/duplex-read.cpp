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
#include "duplex.hpp"

namespace orc {

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

}
