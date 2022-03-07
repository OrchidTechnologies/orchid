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


#ifndef ORCHID_DEFRAGMENT_HPP
#define ORCHID_DEFRAGMENT_HPP

#include "link.hpp"

namespace orc {

// https://datatracker.ietf.org/doc/html/rfc815
// https://datatracker.ietf.org/doc/html/rfc4963
// https://datatracker.ietf.org/doc/html/rfc6864
// https://datatracker.ietf.org/doc/html/rfc8900

class Defragment :
    public Link<Buffer>,
    public Sunken<Pump<Buffer>>
{
  private:
    typedef std::tuple<uint32_t, uint32_t, uint8_t, uint16_t> Fragmented_;

    // XXX: this fails to handle reordered packets
    struct Defragmented_ {
        std::string header_;
        std::string packet_;
    };

    Fragmented_ fragmented_;
    Defragmented_ defragmented_;

  protected:
    void Land(const Buffer &data) override;

  public:
    Defragment(BufferDrain &drain) :
        Link<Buffer>(typeid(*this).name(), drain)
    {
    }

    task<void> Shut() noexcept override {
        co_await Sunken::Shut();
        co_await Link::Shut();
    }

    task<void> Send(const Buffer &data) override {
        co_return co_await Inner().Send(data);
    }
};

}

#endif//ORCHID_DEFRAGMENT_HPP
