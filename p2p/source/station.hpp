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


#ifndef ORCHID_STATION_HPP
#define ORCHID_STATION_HPP

#include "jsonrpc.hpp"
#include "link.hpp"

namespace orc {

class Station :
    public Faucet<Drain<Json::Value>>,
    public Drain<Json::Value>,
    public Sunken<Pump<Json::Value, Json::Value>>
{
  protected:
    void Land(Json::Value data) override;

    void Stop(const std::string &error) noexcept override {
        return Faucet::Stop(error);
    }

  public:
    Station(Drain<Json::Value> &drain) :
        Faucet<Drain<Json::Value>>(drain)
    {
    }

    task<void> Shut() noexcept override {
        co_await Sunken::Shut();
        co_await Faucet::Shut();
    }

    task<void> Send(const std::string &method, const std::string &id, Argument args);
};

}

#endif//ORCHID_STATION_HPP
