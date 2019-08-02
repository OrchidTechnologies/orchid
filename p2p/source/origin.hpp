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


#ifndef ORCHID_ORIGIN_HPP
#define ORCHID_ORIGIN_HPP

#include <rtc_base/openssl_identity.h>
#include <rtc_base/ssl_fingerprint.h>

#include "http.hpp"
#include "link.hpp"
#include "opening.hpp"
#include "socket.hpp"
#include "task.hpp"

namespace orc {

class Origin {
  public:
    virtual ~Origin() = default;

    virtual task<Socket> Associate(Sunk<> *sunk, const std::string &host, const std::string &port) = 0;
    virtual task<Socket> Connect(Sunk<> *sunk, const std::string &host, const std::string &port) = 0;
    virtual task<Socket> Hop(Sunk<> *sunk, const std::function<task<std::string> (std::string)> &respond) = 0;
    virtual task<Socket> Open(Sunk<Opening, ExtendedDrain> *sunk) = 0;

    task<std::string> Request(const std::string &method, const Locator &locator, const std::map<std::string, std::string> &headers, const std::string &data);
};

class Local final :
    public Origin
{
  public:
    task<Socket> Associate(Sunk<> *sunk, const std::string &host, const std::string &port) override;
    task<Socket> Connect(Sunk<> *sunk, const std::string &host, const std::string &port) override;
    task<Socket> Hop(Sunk<> *sunk, const std::function<task<std::string> (std::string)> &respond) override;
    task<Socket> Open(Sunk<Opening, ExtendedDrain> *sunk) override;
};

S<Local> GetLocal();

}

#endif//ORCHID_ORIGIN_HPP
