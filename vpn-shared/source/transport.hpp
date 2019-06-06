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


#ifndef ORCHID_TRANSPORT_HPP
#define ORCHID_TRANSPORT_HPP

#include "link.hpp"

namespace orc {

void Initialize();

class Client;

class Liberator {
  public:
    virtual void Liberate(const Buffer &data) = 0;
};

class Capture :
    public Liberator,
    public BufferDrain
{
  public:
    U<Client> client_;

  protected:
    virtual Link *Inner() = 0;

    void Land(const Buffer &data) override;
    void Stop(const std::string &error) override;

    void Liberate(const Buffer &data) override;

  public:
    Capture(const std::string &ip4);
    ~Capture();

    task<void> Start(std::string ovpnfile, std::string username, std::string password);
};

}

#endif//ORCHID_TRANSPORT_HPP
