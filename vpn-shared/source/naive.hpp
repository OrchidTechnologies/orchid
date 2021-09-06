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


#ifndef ORCHID_NAIVE_HPP
#define ORCHID_NAIVE_HPP

#include "base.hpp"

namespace orc {

class Naive :
    public Base
{
  private:
    Naive(U<rtc::NetworkManager> manager);
  public:
    Naive(const class Host &host);
    Naive();

    class Host Host() override;

    rtc::Thread &Thread() override;
    rtc::BasicPacketSocketFactory &Factory() override;

    task<void> Associate(BufferSunk &sunk, const Socket &endpoint) override;
    task<Socket> Unlid(Sunk<BufferSewer, Opening> &sunk) override;
    task<U<Stream>> Connect(const Socket &endpoint) override;
};

}

#endif//ORCHID_NAIVE_HPP
