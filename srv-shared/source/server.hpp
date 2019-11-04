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


#ifndef ORCHID_SERVER_HPP
#define ORCHID_SERVER_HPP

#include "bond.hpp"
#include "endpoint.hpp"
#include "link.hpp"
#include "jsonrpc.hpp"
#include "shared.hpp"
#include "task.hpp"

namespace orc {

class Server :
    public Bonded,
    public BufferDrain
{
  public:
    S<Server> self_;
    Endpoint endpoint_;
    Address lottery_;

    void Send(const Buffer &data);

  protected:
    virtual Pump *Inner() = 0;

    void Land(Pipe<Buffer> *pipe, const Buffer &data) override;

    void Land(const Buffer &data) override;
    void Stop(const std::string &error) override;

  public:
    Server(Locator locator, Address lottery);

    task<void> Shut() override;

    task<std::string> Respond(const std::string &offer, std::vector<std::string> ice);
};

}

#endif//ORCHID_SERVER_HPP
