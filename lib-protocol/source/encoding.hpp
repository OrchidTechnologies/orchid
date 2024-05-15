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


#ifndef ORCHID_ENCODING_HPP
#define ORCHID_ENCODING_HPP

#include <string>

namespace orc {

#ifdef __WIN32__
inline const wchar_t *w16(const char16_t *value) {
    return reinterpret_cast<const wchar_t *>(value);
}

inline wchar_t *w16(char16_t *value) {
    return reinterpret_cast<wchar_t *>(value);
}

inline const char16_t *w16(const wchar_t *value) {
    return reinterpret_cast<const char16_t *>(value);
}

inline char16_t *w16(wchar_t *value) {
    return reinterpret_cast<char16_t *>(value);
}

std::string utf(const std::u16string &value);
std::u16string utf(const std::string &value);
#endif

}

#endif//ORCHID_ENCODING_HPP
