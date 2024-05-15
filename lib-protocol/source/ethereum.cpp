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


#include "ethereum.hpp"

namespace orc {

task<S<Ethereum>> Ethereum::New(const S<Base> &base, const Locator &locator) {
    co_return Make<Ethereum>(co_await Chain::New({locator, base}, {}, 1));
}

task<S<Ethereum>> Ethereum::New(const S<Base> &base, const std::vector<std::string> &chains) {
    for (const auto &market : chains) {
        const auto [chain, currency, locator] = Split<3>(market, {','});
        if (uint256_t(chain.operator std::string()) == 1)
            co_return co_await Ethereum::New(base, locator.operator std::string());
    }

    orc_assert(false);
}

}
