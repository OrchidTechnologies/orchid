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


#ifndef ORCHID_FAMILY_HPP
#define ORCHID_FAMILY_HPP

#include "link.hpp"

namespace orc {

class Family :
    public Link
{
  private:
    uint32_t Analyze(const Buffer &data) {
        return 2;
    }

  protected:
    virtual Pump *Inner() = 0;

    void Land(const Buffer &data) override {
        auto [protocol, packet] = Take<Number<uint32_t>, Window>(data);
        orc_assert(protocol == Analyze(data));
        return Link::Land(packet);
    }

  public:
    Family(BufferDrain *drain) :
        Link(drain)
    {
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await Inner()->Send(Tie(Number<uint32_t>(Analyze(data)), data));
    }
};

}

#endif//ORCHID_FAMILY_HPP
