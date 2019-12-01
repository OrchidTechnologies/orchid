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


#ifndef ORCHID_LOCAL_HPP
#define ORCHID_LOCAL_HPP

#include "origin.hpp"

namespace orc {

class Local final :
    public Origin
{
  private:
    Local(U<rtc::NetworkManager> manager);
  public:
    Local(const class Host &host);
    Local();

    class Host Host() override;

    rtc::Thread *Thread() override;
    rtc::BasicPacketSocketFactory &Factory() override;

    task<Socket> Associate(Sunk<> *sunk, const std::string &host, const std::string &port) override;
    task<Socket> Connect(U<Stream> &stream, const std::string &host, const std::string &port) override;
    task<Socket> Unlid(Sunk<Opening, BufferSewer> *sunk) override;
};

}

#endif//ORCHID_LOCAL_HPP
