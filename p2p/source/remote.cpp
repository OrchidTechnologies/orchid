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


#include <queue>

#include <cppcoro/async_auto_reset_event.hpp>
#include <cppcoro/async_manual_reset_event.hpp>
#include <cppcoro/async_mutex.hpp>

#include <lwip/err.h>
#include <lwip/ip.h>
#include <lwip/netifapi.h>
#include <lwip/tcp.h>
#include <lwip/tcpip.h>
#include <lwip/udp.h>

#include <p2p/base/basic_packet_socket_factory.h>

#include "dns.hpp"
#include "event.hpp"
#include "fit.hpp"
#include "locked.hpp"
#include "lwip.hpp"
#include "manager.hpp"
#include "remote.hpp"

#define orc_lwipcall(call, expr) ({ \
    const auto _status(call expr); \
    orc_assert_(_status == ERR_OK, "lwip " << #call << ": " << lwip_strerr(_status)); \
_status; })

extern "C" struct netif *hook_ip4_route_src(const ip4_addr_t *src, const ip4_addr_t *dest)
{
    if (src == nullptr)
        return nullptr;
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

    pbuf *Tear() && {
        const auto buffer(buffer_);
        buffer_ = nullptr;
        return buffer;
    }
};

class Buffers :
    public Buffer
{
  private:
    Reference buffer_;

  public:
    // XXX: this always copies, but sometimes I could pbuf_ref? ugh
    Buffers(const Buffer &data) :
        buffer_(pbuf_alloc(PBUF_RAW, Fit(data.size()), PBUF_RAM))
    {
        u16_t offset(0);
        data.each([&](const uint8_t *data, size_t size) {
            orc_lwipcall(pbuf_take_at, (buffer_, data, Fit(size), offset));
            copied_ += size;
            offset += size;
            return true;
        });
    }

    Buffers(pbuf *buffer) :
        buffer_(buffer)
    {
        pbuf_ref(buffer_);
    }

    operator pbuf *() const {
        return buffer_;
    }

    pbuf *Tear() && {
        return std::move(buffer_).Tear();
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

class RemoteCommon {
  protected:
    udp_pcb *pcb_;

    virtual void Land(const Buffer &data, const Socket &socket) = 0;

    RemoteCommon(const ip4_addr_t &host) {
        Core core;
        pcb_ = udp_new();
        orc_assert(pcb_ != nullptr);
        orc_lwipcall(udp_bind, (pcb_, &host, 0));
    }

    ~RemoteCommon() {
        Core core;
        udp_remove(pcb_);
    }

  public:
    operator udp_pcb *() {
        return pcb_;
    }

    void Open(const Core &core) {
        udp_recv(pcb_, [](void *arg, udp_pcb *pcb, pbuf *data, const ip4_addr_t *host, u16_t port) noexcept {
            static_cast<RemoteCommon *>(arg)->Land(Buffers(data), Socket(*host, port));
            pbuf_free(data);
        }, this);
    }

    void Shut() noexcept {
        Core core;
        udp_disconnect(pcb_);
    }
};

class RemoteAssociation :
    public Pump<Buffer>,
    public RemoteCommon
{
  protected:
    void Land(const Buffer &data, const Socket &socket) override {
        Pump::Land(data);
    }

  public:
    RemoteAssociation(BufferDrain &drain, const ip4_addr_t &host) :
        Pump(typeid(*this).name(), drain),
        RemoteCommon(host)
    {
    }

    void Open(const ip4_addr_t &host, uint16_t port) {
        Core core;
        RemoteCommon::Open(core);
        orc_lwipcall(udp_connect, (pcb_, &host, port));
    }

    task<void> Shut() noexcept override {
        RemoteCommon::Shut();
        Pump::Stop();
        co_await Pump::Shut();
    }

    task<void> Send(const Buffer &data) override {
        Core core;
        orc_lwipcall(udp_send, (pcb_, Buffers(data)));
        co_return;
    }
};

class RemoteOpening :
    public Opening,
    public RemoteCommon
{
  protected:
    void Land(const Buffer &data, const Socket &socket) override {
        drain_.Land(data, socket);
    }

  public:
    RemoteOpening(BufferSewer &drain, const ip4_addr_t &host) :
        Opening(typeid(*this).name(), drain),
        RemoteCommon(host)
    {
    }

    Socket Local() const override {
        return Socket(pcb_->local_ip, pcb_->local_port);
    }

    void Open() {
        Core core;
        RemoteCommon::Open(core);
    }

    task<void> Shut() noexcept override {
        RemoteCommon::Shut();
        Opening::Stop();
        co_await Opening::Shut();
    }

    task<void> Send(const Buffer &data, const Socket &socket) override {
        ip4_addr_t address(socket.Host());
        Core core;
        orc_lwipcall(udp_sendto, (pcb_, Buffers(data), &address, socket.Port()));
        co_return;
    }
};

class RemoteConnection final :
    public Stream
{
  private:
    tcp_pcb *pcb_;
    Transfer<err_t> opened_;

    cppcoro::async_mutex send_;
    cppcoro::async_manual_reset_event sent_;

    cppcoro::async_auto_reset_event read_;

    struct Locked_ {
        std::exception_ptr error_;
        std::queue<Beam> data_;
        size_t offset_ = 0;
    }; Locked<Locked_> locked_;

  protected:
    void Land(const Buffer &data) {
        locked_()->data_.emplace(data);
        read_.set();
    }

    void Stop(const std::exception_ptr &error) noexcept {
        if (error != nullptr)
            locked_()->error_ = error;
        else
            locked_()->data_.emplace(Beam());
        read_.set();
    }

  public:
    RemoteConnection(const ip4_addr_t &host) {
        Core core;
        pcb_ = tcp_new();
        orc_assert(pcb_ != nullptr);
        tcp_arg(pcb_, this);
        ip_set_option(pcb_, SOF_KEEPALIVE);
        orc_lwipcall(tcp_bind, (pcb_, &host, 0));
    }

    ~RemoteConnection() override {
        Core core;
        if (pcb_ != nullptr)
            tcp_abort(pcb_);
    }

    task<size_t> Read(const Mutables &buffers) override {
        // XXX: support multiple buffers
        const auto buffer(buffers.begin());
        orc_insist(buffer != buffers.end());
        auto data(static_cast<uint8_t *>(buffer->data()));
        auto size(buffer->size());
        orc_insist(size != 0);

        for (;; co_await read_, co_await Schedule()) {
            const auto locked(locked_());
            if (!locked->data_.empty()) {
                size_t writ(0);

              next:
                const auto &next(locked->data_.front());
                const auto base(next.data());
                const auto rest(next.size() - locked->offset_);
                if (rest == 0)
                    co_return 0;

                const auto have(std::min(size, rest));
                Copy(data, base + locked->offset_, have);
                writ += have;

                if (rest != have)
                    locked->offset_ += have;
                else {
                    locked->data_.pop();
                    locked->offset_ = 0;
                    if (size != have && !locked->data_.empty()) {
                        data += have;
                        size -= have;
                        goto next;
                    }
                }

                co_return writ;
            } else if (locked->error_ != nullptr)
                std::rethrow_exception(locked->error_);
        }
    }

    task<void> Open(const ip4_addr_t &host, uint16_t port) { orc_ahead orc_block({
        { Core core;
            tcp_recv(pcb_, [](void *arg, tcp_pcb *pcb, pbuf *data, err_t error) noexcept -> err_t { orc_head
                const auto self(static_cast<RemoteConnection *>(arg));
                orc_insist(pcb == self->pcb_);
                orc_insist(error == ERR_OK);

                if (data == nullptr)
                    self->Stop(nullptr);
                else {
                    const Buffers buffers(data);
                    self->Land(buffers);
                    tcp_recved(pcb, Fit(buffers.size()));
                    pbuf_free(data);
                }

                return ERR_OK;
            });

            tcp_err(pcb_, [](void *arg, err_t error) noexcept { orc_head
                const auto self(static_cast<RemoteConnection *>(arg));
                orc_insist(self->pcb_ != nullptr);
                orc_insist(error != ERR_OK);

                self->pcb_ = nullptr;
                self->sent_.set();

                if (!self->opened_)
                    self->opened_ = std::move(error);
                else try {
                    orc_lwipcall(, error);
                    orc_insist(false);
                } catch (...) {
                    self->Stop(std::current_exception());
                }
            });

            // XXX: I feel like I should be verifying that size covered the entire sent packet
            tcp_sent(pcb_, [](void *arg, tcp_pcb *pcb, u16_t size) noexcept -> err_t { orc_head
                const auto self(static_cast<RemoteConnection *>(arg));
                orc_insist(pcb == self->pcb_);

                self->sent_.set();
                return ERR_OK;
            });

            orc_lwipcall(tcp_connect, (pcb_, &host, port, [](void *arg, tcp_pcb *pcb, err_t error) noexcept -> err_t { orc_head
                const auto self(static_cast<RemoteConnection *>(arg));
                orc_insist(pcb == self->pcb_);
                orc_insist(error == ERR_OK);

                self->opened_ = std::move(error);
                return ERR_OK;
            }));
        }

        orc_lwipcall(co_await, *opened_);
    }, "connecting to " << Host(host) << ":" << port); }

    // XXX: provide support for tcp_close and unify with Connection's semantics in Stream via Adapter

    void Shut() noexcept override {
        Core core;
        orc_insist(pcb_ != nullptr);
        orc_except({ orc_lwipcall(tcp_shutdown, (pcb_, false, true)); });
    }

    task<void> Send(const Buffer &data) override {
        const auto lock(co_await send_.scoped_lock_async());

        Window window(data);
        auto rest(window.size());

        goto start; do {
            co_await sent_;
            co_await Schedule();

          start:
            Core core;
            orc_assert(pcb_ != nullptr);

            const auto need(tcp_sndbuf(pcb_));
            if (need == 0) {
                sent_.reset();
                continue;
            }

            window.Take(std::min<size_t>(rest, need), [&](const uint8_t *data, size_t size) {
                // XXX: this can't actually happen as need is a uint16_t, but for type safety...
                if (size > 0xffff)
                    size = 0xffff;
                rest -= size;

                // XXX: consider avoiding copies by holding the buffer until send completes
                u8_t flags(TCP_WRITE_FLAG_COPY);
                if (rest != 0)
                    flags |= TCP_WRITE_FLAG_MORE;
                orc_lwipcall(tcp_write, (pcb_, data, Fit(size), flags));
                copied_ += size;
                return size;
            });
        } while (rest != 0);
    }
};

void Remote::Send(pbuf *buffer) {
    // XXX: this always copies the data, but I should sometimes be able to reference it
    // to do this, I think I need to check if !PBUF_NEEDS_COPY _recursively_ for queue?
    nest_.Hatch([&]() noexcept { return [this, data = Beam(Buffers(buffer))]() -> task<void> {
        //Log() << "Remote <<< " << this << " " << data << std::endl;
        co_return co_await Inner().Send(data);
    }; }, __FUNCTION__);
}

err_t Remote::Output(netif *interface, pbuf *buffer, const ip4_addr_t *destination) {
    static_cast<Remote *>(interface->state)->Send(buffer);
    return ERR_OK;
}

err_t Remote::Initialize(netif *interface) {
    interface->name[0] = 'o';
    interface->name[1] = 'r';
    interface->output = &Output;
    return ERR_OK;
}

void Remote::Land(const Buffer &data) {
    //Log() << "Remote >>> " << this << " " << data << std::endl;
    orc_ignore({ orc_assert(tcpip_inpkt(Buffers(data).Tear(), &interface_, interface_.input) == ERR_OK); });
}

void Remote::Stop(const std::string &error) noexcept {
    netifapi_netif_set_link_down(&interface_);
    netifapi_netif_set_down(&interface_);
    netifapi_netif_remove(&interface_);
    Base::Stop();
}

Remote::Remote(const class Host &host) :
    Base(typeid(*this).name(), std::make_unique<Assistant>(host)),
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

void Remote::Open() {
    netifapi_netif_set_up(&interface_);
    netifapi_netif_set_link_up(&interface_);
}

task<void> Remote::Shut() noexcept { orc_ahead
    co_await nest_.Shut();
    co_await Sunken::Shut();
    co_await Valve::Shut();
}

class Host Remote::Host() {
    return host_;
}

rtc::Thread &Remote::Thread() {
    static std::unique_ptr<rtc::Thread> thread;
    if (thread == nullptr) {
        thread = std::make_unique<rtc::Thread>(std::make_unique<LwipSocketServer>());
        thread->SetName("orchid:remote", nullptr);
        thread->Start();
    }

    return *thread;
}

rtc::BasicPacketSocketFactory &Remote::Factory() {
    static rtc::BasicPacketSocketFactory factory(&Thread());
    return factory;
}

task<void> Remote::Associate(BufferSunk &sunk, const Socket &endpoint) {
    auto &association(sunk.Wire<RemoteAssociation>(host_));
    association.Open(endpoint.Host(), endpoint.Port());
    co_return;
}

task<Socket> Remote::Unlid(Sunk<BufferSewer, Opening> &sunk) {
    auto &opening(sunk.Wire<RemoteOpening>(host_));
    opening.Open();
    co_return opening.Local();
}

task<U<Stream>> Remote::Connect(const Socket &endpoint) {
    auto connection(std::make_unique<RemoteConnection>(host_));
    co_await connection->Open(endpoint.Host(), endpoint.Port());
    co_return connection;
}

}
