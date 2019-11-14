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


#include <lwip/ip.h>
#include <lwip/tcpip.h>
#include <lwip/netifapi.h>

#include <p2p/base/basic_packet_socket_factory.h>
#include <p2p/client/basic_port_allocator.h>

#include "lwip.hpp"
#include "remote.hpp"

namespace orc {

class Reference {
  private:
    pbuf *buffer_;

  public:
    Reference() :
        buffer_(nullptr)
    {
    }

    Reference(pbuf *buffer) :
        buffer_(buffer)
    {
        pbuf_ref(buffer_);
    }

    Reference(const Reference &other) = delete;

    Reference(Reference &&other) :
        buffer_(other.buffer_)
    {
        other.buffer_ = nullptr;
    }

    ~Reference() {
        if (buffer_ != nullptr)
            pbuf_free(buffer_);
    }

    operator pbuf *() const {
        return buffer_;
    }

    pbuf *operator ->() const {
        return buffer_;
    }
};

class Chain :
    public Buffer
{
  private:
    Reference buffer_;

  public:
    Chain(const Buffer &data) :
        buffer_(pbuf_alloc(PBUF_RAW, data.size(), PBUF_RAM))
    {
        u16_t offset(0);
        data.each([&](const uint8_t *data, size_t size) {
            orc_assert(pbuf_take_at(buffer_, data, size, offset) == ERR_OK);
            offset += size;
            return true;
        });
    }

    Chain(pbuf *buffer) :
        buffer_(buffer)
    {
    }

    operator pbuf *() const {
        return buffer_;
    }

    bool each(const std::function<bool (const uint8_t *, size_t)> &code) const override {
        for (pbuf *buffer(buffer_); ; buffer = buffer->next) {
            orc_assert(buffer != nullptr);
            if (!code(static_cast<const uint8_t *>(buffer->payload), buffer->len))
                return false;
            if (buffer->tot_len == buffer->len) {
                orc_assert(buffer->next == nullptr);
                return true;
            }
        }
    }
};

task<void> Remote::Send(const Buffer &data) {
    co_return co_await Inner()->Send(data);
}

err_t Remote::Output(netif *interface, pbuf *buffer, const ip4_addr_t *destination) {
    Spawn([interface, data = Chain(buffer)]() -> task<void> {
        co_return co_await static_cast<Remote *>(interface->state)->Send(data);
    });
    return ERR_OK;
}

err_t Remote::Initialize(netif *interface) {
    interface->name[0] = 'o';
    interface->name[1] = 'r';
    interface->output = &Output;
    return ERR_OK;
}

void Remote::Land(const Buffer &data) {
    orc_assert(tcpip_inpkt(Chain(data), &interface_, interface_.input) == ERR_OK);
}

void Remote::Stop(const std::string &error) {
    netifapi_netif_set_link_down(&interface_);
    Origin::Stop();
}

Remote::Remote() {
    static bool setup(false);
    if (!setup) {
        tcpip_init(nullptr, nullptr);
        setup = true;
    }

    static ip4_addr_t gateway; IP4_ADDR(&gateway, 10,7,0,1);
    static ip4_addr_t address; IP4_ADDR(&address, 10,7,0,3);
    static ip4_addr_t netmask; IP4_ADDR(&netmask, 255,255,255,0);

    orc_assert(netifapi_netif_add(&interface_, &address, &netmask, &gateway, nullptr, &Initialize, &ip_input) == ERR_OK);
    interface_.state = this;

    netifapi_netif_set_default(&interface_);
}

Remote::~Remote() {
    netifapi_netif_remove(&interface_);
}

void Remote::Open() {
    netifapi_netif_set_up(&interface_);
    netifapi_netif_set_link_up(&interface_);
}

task<void> Remote::Shut() {
    co_await Inner()->Shut();
    co_await Valve::Shut();
    netifapi_netif_set_down(&interface_);
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

class Assistant :
    public rtc::NetworkManager
{
  private:
    mutable rtc::Network network_;

  public:
    Assistant() :
        network_("or0", "or0", rtc::IPAddress(Host("10.0.0.0")), 8, ADAPTER_TYPE_VPN)
    {
        //network_.set_default_local_address_provider(this);
        network_.AddIP(rtc::IPAddress(Host("10.7.0.3")));
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

U<cricket::PortAllocator> Remote::Allocator() {
    auto thread(Thread());
    static Assistant manager;
    static rtc::BasicPacketSocketFactory packeter(thread);
    return thread->Invoke<U<cricket::PortAllocator>>(RTC_FROM_HERE, [&]() {
        return std::make_unique<cricket::BasicPortAllocator>(&manager, &packeter);
    });
}

task<Socket> Remote::Associate(Sunk<> *sunk, const std::string &host, const std::string &port) {
    orc_insist(false);
}

task<Socket> Remote::Connect(U<Stream> &stream, const std::string &host, const std::string &port) {
    orc_insist(false);
}

task<Socket> Remote::Unlid(Sunk<Opening, BufferSewer> *sunk) {
    orc_insist(false);
}

}
