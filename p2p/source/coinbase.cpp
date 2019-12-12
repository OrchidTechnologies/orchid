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
#include "trace.hpp"

namespace orc {

task<Float> Price(const std::string &from, const std::string &to, const Float &adjust) {
    const auto response(co_await Request("GET", {"https", "api.coinbase.com", "443", "/v2/prices/" + from + "-" + to + "/spot"}, {}, {}));
    const auto result(Parse(response.body_));
    if (response.code_ == boost::beast::http::status::ok) {
        const auto &data(result["data"]);
        co_return Float(data["amount"].asString()) / adjust;
    } else {
        const auto &errors(result["errors"]);
        orc_assert(errors.size() == 1);
        const auto &error(errors[0]);
        const auto id(error["id"].asString());
        const auto message(error["message"].asString());
        if (response.code_ == boost::beast::http::status::not_found && id == "not_found" && message == "Invalid base currency")
            co_return 0;
        orc_throw(response.code_ << "/" << id << ": " << message);
    }
}

}
