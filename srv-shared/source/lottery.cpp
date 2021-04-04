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


#include "lottery.hpp"
#include "time.hpp"

namespace orc {

task<uint128_t> Lottery::Check(const Address &signer, const Address &funder, const Address &recipient) {
    auto &usable(cache_[{signer, funder}]);
    const auto now(Timestamp());
    if (!usable || usable->second < now)
        usable = std::make_pair(co_await Check_(signer, funder, recipient), now + 60);
    co_return usable->first;
}

}
