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


#ifndef ORCHID_EXECUTE_HPP
#define ORCHID_EXECUTE_HPP

#include <cstdlib>
#include <string>

namespace orc {

// XXX: this is an unreasonable implementation to stub the API
template <typename... Args_>
void Execute(const std::string &path, const Args_ &...args) {
    std::ostringstream builder;
    builder << path;
    (void(builder << ' ' << args), ...);
    const auto command(builder.str());
    orc_assert_(system(command.c_str()) == 0, "system(" << command << ") != 0");
}

}

#endif//ORCHID_EXECUTE_HPP
