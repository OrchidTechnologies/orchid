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


#include <json/json.h>

#include "coinbase.hpp"
#include "error.hpp"
#include "http.hpp"
#include "locator.hpp"

namespace orc {

task<cpp_dec_float_50> Price(const std::string &from, const std::string &to) {
    auto body(co_await Request("GET", {"https", "api.coinbase.com", "443", "/v2/prices/" + from + "-" + to + "/spot"}, {}, {}));

    Json::Value result;
    Json::Reader reader;
    orc_assert(reader.parse(body, result, false));

    auto data(result["data"]);
    co_return cpp_dec_float_50(data["amount"].asString());
}

}
