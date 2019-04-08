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


#include <thread>

#include <cppcoro/sync_wait.hpp>

#include "trace.hpp"
#include "spawn.hpp"

namespace orc {

void Spawn(cppcoro::task<void> code) {
    if (false)
        cppcoro::sync_wait(code);
    else {
_trace();
        std::thread([code = std::move(code)]() {
_trace();
            cppcoro::sync_wait(code);
        }).detach();
_trace();
    }
}

}
