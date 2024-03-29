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


#include <chrono>

#include "time.hpp"

namespace orc {

uint64_t Monotonic() {
    // XXX: this isn't actually monotonic; how did that happen?!
    using std::chrono::system_clock;
    const system_clock::time_point point(system_clock::now());
    const system_clock::duration duration(point.time_since_epoch());
    return std::chrono::duration_cast<std::chrono::microseconds>(duration).count();
}

uint64_t Timestamp() {
    using std::chrono::system_clock;
    const system_clock::time_point point(system_clock::now());
    const system_clock::duration duration(point.time_since_epoch());
    return std::chrono::duration_cast<std::chrono::seconds>(duration).count();
}

}
