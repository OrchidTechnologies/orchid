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


#ifndef ORCHID_ERROR_HPP
#define ORCHID_ERROR_HPP

#include <iostream>
#include <sstream>
#include <string>

namespace orc {
class Error {
  public:
    std::string file;
    int line;
    std::string message;

    Error(const std::string &file, int line) :
        file(file), line(line)
    {
    }

    template <typename Type_>
    Error &operator <<(const Type_ &value) {
        std::ostringstream data;
        data << value;
        message += data.str();
        return *this;
    }
}; }

#define _assert_(code, message) do { \
    if ((code)) break; \
    std::cerr << "[" << __FILE__ << ":" << std::dec << __LINE__ << "] " << message << std::endl; \
    throw orc::Error{__FILE__, __LINE__} << message; \
} while (false)

#define _assert(code) \
    _assert_(code, "_assert(" #code ")")

#endif//ORCHID_ERROR_HPP
