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
#include <lwip/netifapi.h>
#include <lwip/tcpip.h>
#include <lwip/udp.h>

#include <p2p/base/basic_packet_socket_factory.h>

#include "dns.hpp"
#include "lwip.hpp"
#include "manager.hpp"
#include "remote.hpp"

#define orc_lwipcall(expr) \
    orc_assert((expr) == ERR_OK)

extern "C" struct netif *hook_ip4_route_src(const ip4_addr_t *src, const ip4_addr_t *dest)
{
    struct netif *netif;
    NETIF_FOREACH(netif) {
        if (netif_is_up(netif) && netif_is_link_up(netif) && ip4_addr_cmp(src, netif_ip4_addr(netif))) {
            return netif;
        }
    }
    return nullptr;
}

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

    Reference(Reference &&other) noexcept :
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

class Core {
  public:
    Core() {
        sys_lock_tcpip_core();
    }

    ~Core() {
        sys_unlock_tcpip_core();
    }
};

class Base {
  protected:
    udp_pcb *pcb_;

    virtual void Land(const Buffer &data, const Socket &socket) = 0;

    static void Land(void *arg, udp_pcb *pcb, pbuf *data, const ip4_addr_t *host, u16_t port) {
        static_cast<Base *>(arg)->Land(Chain(data), Socket(*host, port));
    }

    Base(const ip4_addr_t &host) {
        Core core;
        pcb_ = udp_new();
        orc_assert(pcb_ != nullptr);
        orc_lwipcall(udp_bind(pcb_, &host, 0));
    }

    ~Base() {
        Core core;
        udp_remove(pcb_);
    }

  public:
    operator udp_pcb *() {
        return pcb_;
    }

    void Open() {
        Core core;
        udp_recv(pcb_, &Land, this);
    }
};

class Association :
    public Pump<Buffer>,
    public Base
{
  protected:
    void Land(const Buffer &data, const Socket &socket) override {
        Pump::Land(data);
    }

  public:
    Association(BufferDrain *drain, const ip4_addr_t &host) :
        Pump(drain),
        Base(host)
    {
    }

    void Open(const ip4_addr_t &host, uint16_t port) {
        Base::Open();
        { Core core;
            orc_lwipcall(udp_connect(pcb_, &host, port)); }
    }

    task<void> Shut() override {
        { Core core;
            udp_disconnect(pcb_); }
        co_await Pump::Shut();
    }

    task<void> Send(const Buffer &data) override {
        { Core core;
            orc_lwipcall(udp_send(pcb_, Chain(data))); }
        co_return;
    }
};

class RemoteOpening final :
    public Opening,
    public Base
{
  protected:
    void Land(const Buffer &data, const Socket &socket) override {
        drain_->Land(data, socket);
    }

  public:
    RemoteOpening(BufferSewer *drain, const ip4_addr_t &host) :
        Opening(drain),
        Base(host)
    {
    }

    Socket Local() const override {
        return Socket(pcb_->local_ip, pcb_->local_port);
    }

    task<void> Shut() override {
        co_return;
    }

    task<void> Send(const Buffer &data, const Socket &socket) override {
        ip4_addr_t address(socket.Host());
        { Core core;
            orc_lwipcall(udp_sendto(pcb_, Chain(data), &address, socket.Port())); }
        co_return;
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

Remote::Remote(const class Host &host) :
    Origin(std::make_unique<Assistant>(host)),
    host_(host)
{
    static bool setup(false);
    if (!setup) {
        tcpip_init(nullptr, nullptr);
        setup = true;
    }

    ip4_addr_t gateway; IP4_ADDR(&gateway, 10,7,0,1);
    ip4_addr_t address(host_);
    ip4_addr_t netmask; IP4_ADDR(&netmask, 255,255,255,0);

    orc_assert(netifapi_netif_add(&interface_, &address, &netmask, &gateway, this, &Initialize, &ip_input) == ERR_OK);
}

static uint8_t quad_(3);

Remote::Remote() :
    Remote({10,7,0,++quad_})
{
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

class Host Remote::Host() {
    return host_;
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

rtc::BasicPacketSocketFactory &Remote::Factory() {
    static rtc::BasicPacketSocketFactory factory(Thread());
    return factory;
}

task<Socket> Remote::Associate(Sunk<> *sunk, const std::string &host, const std::string &port) {
    auto association(sunk->Wire<Association>(host_));
    auto results(co_await Resolve(*this, host, port));
    for (auto &result : results) {
        Socket socket(result);
        // XXX: socket.Host() should return a class Host
        association->Open(orc::Host(socket.Host()), socket.Port());
        co_return socket;
    }
    orc_assert(false);
}

task<Socket> Remote::Connect(U<Stream> &stream, const std::string &host, const std::string &port) {
    orc_insist(false);
}

task<Socket> Remote::Unlid(Sunk<BufferSewer, Opening> *sunk) {
    auto opening(sunk->Wire<RemoteOpening>(host_));
    opening->Open();
    co_return opening->Local();
}

}
