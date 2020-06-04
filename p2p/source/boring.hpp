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


#ifndef ORCHID_BORING_HPP
#define ORCHID_BORING_HPP

#include "link.hpp"
#include "nest.hpp"
#include "socket.hpp"

struct wireguard_tunnel;

namespace orc {

class Origin;

class Boring :
    public Link<Buffer>,
    public Sunken<Pump<Buffer>>
{
  private:
    uint32_t local_;
    uint32_t remote_;

    wireguard_tunnel *const wireguard_;

    volatile bool stop_ = false;
    Nest nest_;
    Event done_;

    void Error();

  protected:
    void Land(const Buffer &data) override;
    void Stop(const std::string &error) noexcept override;

  public:
    Boring(BufferDrain &drain, uint32_t local, const Host &remote, const std::string &secret, const std::string &common);
    ~Boring() override;

    void Open();
    task<void> Shut() noexcept override;
    task<void> Send(const Buffer &data) override;
};

task<void> Guard(BufferSunk &sunk, S<Origin> origin, uint32_t local, std::string file);

}

#endif//ORCHID_BORING_HPP
