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

class Socket {
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

    template <typename Protocol_>
    Socket(const asio::ip::basic_endpoint<Protocol_> &endpoint) :
        host_(endpoint.address()),
        port_(endpoint.port())
    {
    }

    Socket(const Socket &rhs) = default;

    Socket(Socket &&rhs) noexcept :
        host_(std::move(rhs.host_)),
        port_(rhs.port_)
    {
    }

    Socket &operator =(const Socket &rhs) = default;

    Socket &operator =(Socket &&rhs) noexcept {
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

    bool operator ==(const Socket &rhs) const {
        return std::tie(host_, port_) == std::tie(rhs.host_, rhs.port_);
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

    Four(const Four &rhs) = default;

    Four(Four &&rhs) noexcept :
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

    bool operator ==(const Four &rhs) const {
        return std::tie(source_, target_) == std::tie(rhs.source_, rhs.target_);
    }
};

inline std::ostream &operator <<(std::ostream &out, const Four &four) {
    return out << "[" << four.Source() << "|" << four.Target() << "]";
}

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

    Five(const Five &rhs) = default;

    Five(Five &&rhs) noexcept :
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

    bool operator ==(const Five &rhs) const {
        return std::tie(protocol_, Source(), Target()) == std::tie(rhs.protocol_, rhs.Source(), rhs.Target());
    }
};

inline std::ostream &operator <<(std::ostream &out, const Five &five) {
    return out << "[" << five.Protocol() << "|" << five.Source() << "|" << five.Target() << "]";
}

class Three final :
    public Socket
{
  private:
    uint8_t protocol_;

  public:
    template <typename... Args_>
    Three(uint8_t protocol, Args_ &&...args) :
        Socket(std::forward<Args_>(args)...),
        protocol_(protocol)
    {
    }

    Three(const Three &rhs) = default;

    Three(Three &&rhs) noexcept :
        Socket(std::move(rhs)),
        protocol_(rhs.protocol_)
    {
    }

    uint8_t Protocol() const {
        return protocol_;
    }

    std::tuple<uint8_t, const Socket &> Tuple() const {
        return std::tie(protocol_, *this);
    }

    bool operator <(const Three &rhs) const {
        return Tuple() < rhs.Tuple();
    }

    bool operator ==(const Three &rhs) const {
        return Tuple() == rhs.Tuple();
    }
};

inline std::ostream &operator <<(std::ostream &out, const Three &three) {
    return out << "[" << three.Protocol() << "|" << static_cast<const Socket &>(three) << "]";
}

}

#endif//ORCHID_SOCKET_HPP
