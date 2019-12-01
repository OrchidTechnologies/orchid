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


#ifndef ORCHID_MANAGER_HPP
#define ORCHID_MANAGER_HPP

#include <rtc_base/network.h>

#include "port.hpp"
#include "socket.hpp"

namespace orc {

class Manager :
    public rtc::BasicNetworkManager
{
  public:
    void GetNetworks(NetworkList *networks) const override {
        rtc::BasicNetworkManager::GetNetworks(networks);
        for (auto network : *networks)
            Log() << "NET: " << network->ToString() << "@" << network->GetBestIP().ToString() << std::endl;
        networks->erase(std::remove_if(networks->begin(), networks->end(), [](auto network) {
            return Host(network->GetBestIP()) == Host_;
        }), networks->end());
    }
};

class Assistant :
    public rtc::NetworkManager
{
  private:
    mutable rtc::Network network_;

  public:
    Assistant(const Host &host, const std::string &name, const Host &network, unsigned bits) :
        network_(name, name, network, bits, rtc::ADAPTER_TYPE_VPN)
    {
        //network_.set_default_local_address_provider(this);
        network_.AddIP(host);
    }

    Assistant(const Host &host, const std::string &name) :
        Assistant(host, name, host, 32)
    {
    }

    Assistant(const Host &host) :
        Assistant(host, "or" + std::to_string(reinterpret_cast<uintptr_t>(this)))
    {
    }

    void StartUpdating() override {
        SignalNetworksChanged();
    }

    void StopUpdating() override {
    }

    void GetNetworks(NetworkList *networks) const override {
        networks->clear();
        networks->emplace_back(&network_);
    }
};

}

#endif//ORCHID_MANAGER_HPP
