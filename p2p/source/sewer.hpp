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


#ifndef ORCHID_SEWER_HPP
#define ORCHID_SEWER_HPP

#include "buffer.hpp"
#include "socket.hpp"

namespace orc {

template <typename Type_>
class Sewer {
  public:
    virtual void Land(Type_ data, Socket socket) = 0;
    virtual void Stop(const std::string &error = std::string()) = 0;
};

using BufferSewer = Sewer<const Buffer &>;

}

#endif//ORCHID_SEWER_HPP
