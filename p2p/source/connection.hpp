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

#include <cppcoro/async_manual_reset_event.hpp>
#include <cppcoro/async_mutex.hpp>

#include "baton.hpp"
#include "link.hpp"
#include "reader.hpp"
#include "task.hpp"

namespace orc {

template <typename Connection_>
class Connection final :
    public Stream
{
  protected:
    Connection_ connection_;

    struct Log_ {
        std::chrono::steady_clock::time_point timestamp_;
        uint16_t length_;
    };
    std::deque<Log_> log_;
    uint64_t log_total_;
    int64_t min_delay_;

  public:
    template <typename... Args_>
    Connection(Args_ &&...args) :
        connection_(std::forward<Args_>(args)...),
        log_total_(0),
        min_delay_(UINT64_MAX)
    {
    }

    ~Connection() {
        Log() << this << " " << __func__;
        if (!UpdateCost()) {
            Log() << __func__ << " unaccounted buffer bytes " << log_total_;
        }
    }

    Connection_ *operator ->() {
        return &connection_;
    }

    bool UpdateCost() override {
        auto fd = connection_.native_handle();
        int outstanding = 0;
#if defined(__linux__)
        if (ioctl(fd, SIOCOUTQ, &outstanding) < 0)
            return true;
#elif defined(__APPLE__)
        socklen_t optlen = sizeof(outstanding);
        if (getsockopt(fd, SOL_SOCKET, SO_NWRITE, &outstanding, &optlen) < 0)
            return true;
#elif defined(__WIN32__)
#error "use GetPerTcpConnectionEStats(.. TcpConnectionEstatsSendBuff ..) "
#endif
        uint64_t total_cost = 0;
        while (log_total_ > outstanding) {
            auto l = log_.front();
            log_.pop_front();
            log_total_ -= l.length_;
            auto delay = std::chrono::duration_cast<std::chrono::microseconds>(std::chrono::steady_clock::now() - l.timestamp_).count();
            min_delay_ = std::max(1LL, std::min(min_delay_, delay));
            delay -= min_delay_;
            auto cost = delay * l.length_;
            Log() << "min_delay:" << min_delay_ << " delay:" << delay << " length:" << l.length_ << " cost:" << cost;
            total_cost += cost;
        }
        Log() << "total_cost:" << total_cost;
        return log_total_ == 0;
    }

    task<size_t> Read(Beam &beam) override {
        size_t writ;
        try {
            writ = co_await connection_.async_receive(asio::buffer(beam.data(), beam.size()), Token());
        } catch (const asio::system_error &error) {
            auto code(error.code());
            if (code == asio::error::eof)
                co_return 0;
            orc_adapt(error);
        }

        if (Verbose)
            Log() << "\e[33mRECV " << writ << " " << beam.subset(0, writ) << "\e[0m" << std::endl;
        co_return writ;
    }

    task<boost::asio::ip::basic_endpoint<typename Connection_::protocol_type>> Open(const std::string &host, const std::string &port) {
        auto endpoints(co_await asio::ip::basic_resolver<typename Connection_::protocol_type>(Context()).async_resolve({host, port}, Token()));
        if (Verbose)
            for (auto &endpoint : endpoints)
                Log() << endpoint.host_name() << ":" << endpoint.service_name() << " :: " << endpoint.endpoint() << std::endl;
        auto endpoint(co_await asio::async_connect(connection_, endpoints, Token()));
        connection_.non_blocking(true);
        co_return endpoint;
    }

    task<void> Shut() override {
        try {
            connection_.shutdown(Connection_::protocol_type::socket::shutdown_send);
        } catch (const asio::system_error &error) {
            auto code(error.code());
            if (code == asio::error::not_connected)
                co_return;
            orc_adapt(error);
        }
    }

    task<void> Send(const Buffer &data) override {
        if (Verbose)
            Log() << "\e[35mSEND " << data.size() << " " << data << "\e[0m" << std::endl;

        size_t writ;
        try {
            writ = co_await connection_.async_send(Sequence(data), Token());
        } catch (const asio::system_error &error) {
            orc_adapt(error);
        }
        orc_assert_(writ == data.size(), "orc_assert(" << writ << " {writ} == " << data.size() << " {data.size()})");

        log_.push_back(Log_{std::chrono::steady_clock::now(), static_cast<uint16_t>(writ)});
        log_total_ += writ;
    }
};

}

#endif//ORCHID_CONNECTION_HPP
