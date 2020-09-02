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


#ifndef ORCHID_CONNECTION_HPP
#define ORCHID_CONNECTION_HPP

#include <asio/ip/tcp.hpp>
#include <asio/ip/udp.hpp>

#include <lwipopts.h>

#include "baton.hpp"
#include "dns.hpp"
#include "link.hpp"
#include "reader.hpp"
#include "socket.hpp"
#include "task.hpp"

#if 0
#elif defined(__APPLE__)
#define TCP_KEEPIDLE TCP_KEEPALIVE
#elif defined(_WIN32)
#define TCP_KEEPALIVE 3
#define TCP_MAXRT 5
#define TCP_KEEPIDLE TCP_KEEPALIVE
#define TCP_KEEPCNT 16
#define TCP_KEEPINTVL 17
#elif defined(__linux__)
#define TCP_USER_TIMEOUT 18
#endif

namespace orc {

template <typename Association_>
class Association :
    public Stream
{
  protected:
    Association_ association_;

  public:
    template <typename... Args_>
    Association(Args_ &&...args) noexcept(noexcept(Association_(std::forward<Args_>(args)...))) :
        association_(std::forward<Args_>(args)...)
    {
    }

    Association_ *operator ->() {
        return &association_;
    }

    task<size_t> Read(const Mutables &buffers) override {
        size_t writ;
        try {
            writ = co_await association_.async_receive(buffers, Token());
        } catch (const asio::system_error &error) {
            auto code(error.code());
            if (code == asio::error::eof)
                co_return 0;
            orc_adapt(error);
        }

        //Log() << "\e[33mRECV " << writ << " " << beam.subset(0, writ) << "\e[0m" << std::endl;
        co_return writ;
    }

    virtual task<void> Open(const Socket &endpoint) { orc_ahead orc_block({
        co_await association_.async_connect(endpoint, Token());
        association_.non_blocking(true);
    }, "connecting to " << endpoint); }

    void Shut() noexcept override {
        association_.close();
    }

    task<void> Send(const Buffer &data) override {
        //Log() << "\e[35mSEND " << data.size() << " " << data << "\e[0m" << std::endl;

        const size_t writ(co_await [&]() -> task<size_t> { try {
            co_return co_await association_.async_send(Sequence(data), Token());
        } catch (const asio::system_error &error) {
            orc_adapt(error);
        } }());
        orc_assert_(writ == data.size(), "orc_assert(" << writ << " {writ} == " << data.size() << " {data.size()})");
    }
};

class Connection :
    public Association<asio::ip::tcp::socket>
{
  public:
    using Association::Association;

    task<void> Open(const Socket &endpoint) override {
        association_.open(endpoint.Host().v4() ? asio::ip::tcp::v4() : asio::ip::tcp::v6());

        association_.set_option(asio::ip::tcp::socket::keep_alive(true));

        // XXX: consider setting keepalive timeout separately for connection than from actual data

        // XXX: we maybe should be using SIO_KEEPALIVE_VALS via WSAIoctl on Win32 instead of TCP_KEEP*
        // XXX: https://docs.microsoft.com/en-us/previous-versions/windows/desktop/legacy/dd877220(v=vs.85)
        // XXX: https://bugs.python.org/issue34932 https://bugs.python.org/issue32394

        association_.set_option(asio::detail::socket_option::integer<IPPROTO_TCP, TCP_KEEPIDLE>(TCP_KEEPIDLE_DEFAULT / 1000));
        association_.set_option(asio::detail::socket_option::integer<IPPROTO_TCP, TCP_KEEPINTVL>(TCP_KEEPINTVL_DEFAULT / 1000));
        association_.set_option(asio::detail::socket_option::integer<IPPROTO_TCP, TCP_KEEPCNT>(TCP_KEEPCNT_DEFAULT));

        const auto timeout(TCP_KEEPIDLE_DEFAULT + TCP_KEEPINTVL_DEFAULT * TCP_KEEPCNT_DEFAULT);
#if 0
#elif defined(__APPLE__)
        association_.set_option(asio::detail::socket_option::integer<IPPROTO_TCP, TCP_CONNECTIONTIMEOUT>(timeout / 1000));
#elif defined(_WIN32)
        association_.set_option(asio::detail::socket_option::integer<IPPROTO_TCP, TCP_MAXRT>(timeout / 1000));
#elif defined(__linux__)
        // XXX: consider configuring TCP_SYNCNT
        // "The retries are staggered at 1s, 3s, 7s, 15s, 31s, 63s marks (the inter-retry time starts at 2s and then doubles each time)."
        // XXX: this is only on Linux 2.6.37+, so we will get an error that needs to be handled on CentOS 6
        association_.set_option(asio::detail::socket_option::integer<IPPROTO_TCP, TCP_USER_TIMEOUT>(timeout));
#endif

        co_return co_await Association::Open(endpoint);
    }

    void Shut() noexcept override {
        try {
            association_.shutdown(asio::ip::tcp::socket::shutdown_send);
        } catch (const asio::system_error &error) {
            const auto code(error.code());
            if (code == asio::error::not_connected)
                return;
            orc_except({ orc_adapt(error); })
        }
    }
};

}

#endif//ORCHID_CONNECTION_HPP
