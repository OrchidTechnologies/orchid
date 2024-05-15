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


#ifndef ORCHID_SEWER_HPP
#define ORCHID_SEWER_HPP

#include "buffer.hpp"
#include "socket.hpp"

namespace orc {

template <typename Type_>
class Sewer {
  public:
    virtual ~Sewer() = default;

    virtual void Land(Type_ data, Socket socket) = 0;
    virtual void Stop(const std::string &error = std::string()) noexcept = 0;
};

using BufferSewer = Sewer<const Buffer &>;

class Opening :
    public Valve
{
  protected:
    BufferSewer &drain_;

  public:
    template <typename... Args_>
    Opening(const char *type, BufferSewer &drain) :
        Valve(type),
        drain_(drain)
    {
    }

    virtual Socket Local() const = 0;
    virtual task<void> Send(const Buffer &data, const Socket &socket) = 0;
};

}

#endif//ORCHID_SEWER_HPP
