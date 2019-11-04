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


#include <p2p/base/basic_packet_socket_factory.h>
#include <p2p/client/basic_port_allocator.h>
#include <rtc_base/async_invoker.h>

#include "log.hpp"
#include "shared.hpp"
#include "threads.hpp"

namespace orc {

class Manager :
    public rtc::BasicNetworkManager
{
  public:
    void GetNetworks(NetworkList *networks) const override {
        rtc::BasicNetworkManager::GetNetworks(networks);
        for (auto network : *networks)
            Log() << "NET: " << network->ToString() << "@" << network->GetBestIP().ToString() << std::endl;
        for (auto network(networks->begin()); network != networks->end(); ++network)
            if ((*network)->GetBestIP().ToString() == "10.7.0.3") {
                networks->erase(network);
                break;
            }
    }
};

U<cricket::PortAllocator> GetAllocator() {
    auto &threads(Threads::Get());
    static Manager manager;
    static rtc::BasicPacketSocketFactory packeter(threads.network_.get());
    return threads.network_->Invoke<U<cricket::PortAllocator>>(RTC_FROM_HERE, [&]() {
        return std::make_unique<cricket::BasicPortAllocator>(&manager, &packeter);
    });
}

}
