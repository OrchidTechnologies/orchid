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


#ifndef ORCHID_SOCKET_HPP
#define ORCHID_SOCKET_HPP

#include <iostream>
#include <string>

#include <asio.hpp>

namespace orc {

class Socket final {
  private:
    asio::ip::address host_;
    uint16_t port_;

  public:
    Socket() :
        port_(0)
    {
    }

    Socket(asio::ip::address host, uint16_t port) :
        host_(std::move(host)),
        port_(port)
    {
    }

    Socket(const std::string &host, uint16_t port) :
        host_(asio::ip::make_address(host)),
        port_(port)
    {
    }

    Socket(uint32_t host, uint16_t port) :
        host_(asio::ip::address_v4(host)),
        port_(port)
    {
    }

    Socket(asio::ip::udp::endpoint endpoint) :
        host_(endpoint.address()),
        port_(endpoint.port())
    {
    }

    Socket(const Socket &rhs) :
        host_(rhs.host_),
        port_(rhs.port_)
    {
    }

    Socket(Socket &&rhs) :
        host_(std::move(rhs.host_)),
        port_(rhs.port_)
    {
    }

    Socket &operator =(const Socket &rhs) {
        host_ = rhs.host_;
        port_ = rhs.port_;
        return *this;
    }

    Socket &operator =(Socket &&rhs) {
        host_ = std::move(rhs.host_);
        port_ = rhs.port_;
        return *this;
    }

    const asio::ip::address &Host() const {
        return host_;
    }

    uint16_t Port() const {
        return port_;
    }

    bool operator <(const Socket &rhs) const {
        return std::tie(host_, port_) < std::tie(rhs.host_, rhs.port_);
    }
};

inline std::ostream &operator <<(std::ostream &out, const Socket &socket) {
    return out << socket.Host() << ":" << socket.Port();
}

class Four {
  private:
    Socket source_;
    Socket target_;

  public:
    Four(Socket source, Socket target) :
        source_(std::move(source)),
        target_(std::move(target))
    {
    }

    Four(const Four &rhs) :
        source_(rhs.source_),
        target_(rhs.target_)
    {
    }

    Four(Four &&rhs) :
        source_(std::move(rhs.source_)),
        target_(std::move(rhs.target_))
    {
    }

    const Socket &Source() const {
        return source_;
    }

    const Socket &Target() const {
        return target_;
    }

    bool operator <(const Four &rhs) const {
        return std::tie(source_, target_) < std::tie(rhs.source_, rhs.target_);
    }
};

class Five final :
    public Four
{
  private:
    uint8_t protocol_;

  public:
    Five(uint8_t protocol, Socket source, Socket target) :
        Four(std::move(source), std::move(target)),
        protocol_(protocol)
    {
    }

    Five(const Five &rhs) :
        Four(rhs),
        protocol_(rhs.protocol_)
    {
    }

    Five(Five &&rhs) :
        Four(std::move(rhs)),
        protocol_(rhs.protocol_)
    {
    }

    uint8_t Protocol() const {
        return protocol_;
    }

    bool operator <(const Five &rhs) const {
        return std::tie(protocol_, Source(), Target()) < std::tie(rhs.protocol_, rhs.Source(), rhs.Target());
    }
};

inline std::ostream &operator <<(std::ostream &out, const Five &five) {
    return out << five.Protocol() << "[" << five.Source() << " -> " << five.Target() << "]";
}

}

#endif//ORCHID_SOCKET_HPP
