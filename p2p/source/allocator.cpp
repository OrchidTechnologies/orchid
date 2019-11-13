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

#include "local.hpp"
#include "log.hpp"
#include "lwip.hpp"
#include "remote.hpp"
#include "shared.hpp"
#include "threads.hpp"

namespace orc {

rtc::Thread *Local::Thread() {
    static std::unique_ptr<rtc::Thread> thread;
    if (thread == nullptr) {
        thread = rtc::Thread::CreateWithSocketServer();
        thread->SetName("Orchid WebRTC Local", nullptr);
        thread->Start();
    }

    return thread.get();
}

rtc::Thread *Remote::Thread() {
    static std::unique_ptr<rtc::Thread> thread;
    if (thread == nullptr) {
        thread = std::make_unique<rtc::Thread>(std::make_unique<LwipSocketServer>());
        thread->SetName("Orchid WebRTC Remote", nullptr);
        thread->Start();
    }

    return thread.get();
}

class Manager :
    public rtc::BasicNetworkManager
{
  public:
    void GetNetworks(NetworkList *networks) const override {
        rtc::BasicNetworkManager::GetNetworks(networks);
        for (auto network : *networks)
            Log() << "NET: " << network->ToString() << "@" << network->GetBestIP().ToString() << std::endl;
        std::remove_if(networks->begin(), networks->end(), [](auto network) {
            return network->GetBestIP().ToString() == "10.7.0.3";
        });
    }
};

U<cricket::PortAllocator> Local::Allocator() {
    auto thread(Thread());
    static Manager manager;
    static rtc::BasicPacketSocketFactory packeter(thread);
    return thread->Invoke<U<cricket::PortAllocator>>(RTC_FROM_HERE, [&]() {
        return std::make_unique<cricket::BasicPortAllocator>(&manager, &packeter);
    });
}

U<cricket::PortAllocator> Remote::Allocator() {
    auto thread(Thread());
    static rtc::BasicNetworkManager manager;
    static rtc::BasicPacketSocketFactory packeter(thread);
    return thread->Invoke<U<cricket::PortAllocator>>(RTC_FROM_HERE, [&]() {
        return std::make_unique<cricket::BasicPortAllocator>(&manager, &packeter);
    });
}

}
