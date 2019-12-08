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


#include "coinbase.hpp"
#include "error.hpp"
#include "http.hpp"
#include "json.hpp"
#include "locator.hpp"

namespace orc {

static Float Ten18("1000000000000000000");

task<Float> Price(const std::string &from, const std::string &to) {
    const auto result(Parse(co_await Request("GET", {"https", "api.coinbase.com", "443", "/v2/prices/" + from + "-" + to + "/spot"}, {}, {})));
    const auto data(result["data"]);
    co_return Float(data["amount"].asString()) / Ten18;
}

}
