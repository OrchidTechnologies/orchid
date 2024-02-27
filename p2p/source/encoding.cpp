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


// XXX: this code is from Impactor, where I have at least three implementations of this...
#ifdef _WIN32

#include <windows.h>

#include "encoding.hpp"
#include "error.hpp"
#include "fit.hpp"

namespace orc {

std::string utf(const std::u16string &value) {
    std::string data;
    if (value.empty())
        return data;
    data.resize(value.size() * 5);
    const int writ(WideCharToMultiByte(CP_UTF8, 0, w16(value.data()), Fit(value.size()), &data[0], Fit(data.size() * sizeof(data[0])), nullptr, nullptr))
;
    orc_assert(writ != 0);
    data.resize(writ / sizeof(data[0]));
    return data;
}

std::u16string utf(const std::string &value) {
    std::u16string data;
    if (value.empty())
        return data;
    data.resize(value.size());
    const int writ(MultiByteToWideChar(CP_UTF8, 0, value.data(), Fit(value.size() * sizeof(value[0])), w16(&data[0]), Fit(data.size())));
    orc_assert(writ != 0);
    data.resize(writ);
    return data;
}

}

#endif
