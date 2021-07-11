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


#include <boost/beast/core/detail/base64.hpp>

#include "base64.hpp"
#include "crypto.hpp"

namespace orc {

std::string ToBase64(const Region &data) {
    using namespace boost::beast::detail::base64;
    std::string encoded;
    encoded.resize(encoded_size(data.size()));
    encoded.resize(encode(&encoded[0], data.data(), data.size()));
    return encoded;
}

Beam FromBase64(const std::string &data) {
    using namespace boost::beast::detail::base64;
    Beam decoded(decoded_size(data.size()));
    const auto result(decode(decoded.data(), data.data(), data.size()));
    orc_assert(result.second <= data.size());
    // XXX: I must misunderstand this API, right? there's no way this doesn't count =
    for (auto i(result.second); i != data.size(); ++i)
        orc_assert(data[i] == '=');
    decoded.size(result.first);
    return decoded;
}

}
