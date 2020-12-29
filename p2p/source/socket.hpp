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


#ifndef ORCHID_SOCKET_HPP
#define ORCHID_SOCKET_HPP

#include <iostream>
#include <string>

#include <boost/algorithm/string/predicate.hpp>
#include <boost/endian/conversion.hpp>

#include <lwip/ip4_addr.h>
#include <rtc_base/socket_address.h>

#include <asio.hpp>
#include "error.hpp"

namespace orc {

class Host {
  private:
    std::array<uint8_t, 16> data_;

    explicit Host(const uint8_t *data) {
        memcpy(data_.data(), data, 16);
    }

  public:
    Host(uint8_t q0, uint8_t q1, uint8_t q2, uint8_t q3) :
        data_({0,0,0,0, 0,0,0,0, 0,0,0xff,0xff, q0,q1,q2,q3,})
    {
    }

    Host(uint32_t host) :
        Host(host >> 24, host >> 16, host >> 8, host)
    {
    }

    Host(const std::array<uint8_t, 16> &host) :
        Host(host.data())
    {
    }

    Host(const std::array<uint8_t, 4> &host) :
        Host(host[0], host[1], host[2], host[3])
    {
    }

    Host(const in6_addr &host) :
        Host(host.s6_addr)
    {
    }

    Host(const in_addr &host) :
        Host(boost::endian::big_to_native(host.s_addr))
    {
    }

    Host(const ip4_addr_t &host) :
        Host(boost::endian::big_to_native(host.addr))
    {
    }

    Host(const asio::ip::address &host) :
        Host((host.is_v6() ? host.to_v6() : asio::ip::make_address_v6(asio::ip::v4_mapped, host.to_v4())).to_bytes())
    {
    }

    Host(const rtc::IPAddress &host) :
        Host(host.AsIPv6Address().ipv6_address())
    {
    }

    Host(const std::string &host) :
        Host([&]() {
            rtc::IPAddress address;
            orc_assert_(IPFromString(host, &address), host << " is not a Host");
            return address;
        }())
    {
    }

    Host(const char *host) :
        Host(std::string(host))
    {
    }

    Host() :
        Host(uint32_t(0))
    {
    }

    bool v4() const {
        return memcmp(data_.data(), static_cast<const void *>((const uint8_t[]) {0,0,0,0, 0,0,0,0, 0,0,0xff,0xff}), 12) == 0;
    }

    explicit operator uint32_t() const {
        orc_assert(v4());
        return data_[12] << 24 | data_[13] << 16 | data_[14] << 8 | data_[15];
    }

    operator in6_addr() const {
        in6_addr address;
        memcpy(address.s6_addr, data_.data(), 16);
        return address;
    }

    operator in_addr() const {
        in_addr address;
        address.s_addr = boost::endian::native_to_big(operator uint32_t());
        return address;
    }

    operator ip4_addr_t() const {
        ip4_addr_t address;
        address.addr = boost::endian::native_to_big(operator uint32_t());
        return address;
    }

    operator asio::ip::address() const {
        if (v4())
            return asio::ip::make_address_v4(std::array<uint8_t, 4>({data_[12], data_[13], data_[14], data_[15]}));
        else
            return asio::ip::make_address_v6(data_);
    }

    operator rtc::IPAddress() const {
        if (v4())
            return rtc::IPAddress(operator in_addr());
        else
            return rtc::IPAddress(operator in6_addr());
    }

    explicit operator std::string() const {
        return operator asio::ip::address().to_string();
    }

    // XXX: this should return Masked
    std::string operator /(unsigned mask) const {
        return operator std::string() + "/" + std::to_string(mask);
    }

    bool operator <(const Host &rhs) const {
        return data_ < rhs.data_;
    }

    bool operator ==(const Host &rhs) const {
        return data_ == rhs.data_;
    }

    bool operator !=(const Host &rhs) const {
        return data_ != rhs.data_;
    }
};

inline std::ostream &operator <<(std::ostream &out, const Host &host) {
    return out << host.operator std::string();
}

class Socket {
  private:
    Host host_;
    uint16_t port_;

    std::tuple<const Host &, uint16_t> Tuple() const {
        return std::tie(host_, port_);
    }

  public:
    Socket() :
        port_(0)
    {
    }

    Socket(Host host, uint16_t port) :
        host_(host),
        port_(port)
    {
    }

    Socket(const asio::ip::address &host, uint16_t port) :
        host_(host),
        port_(port)
    {
    }

    template <typename Protocol_>
    Socket(const asio::ip::basic_endpoint<Protocol_> &endpoint) :
        host_(endpoint.address()),
        port_(endpoint.port())
    {
    }

    Socket(const rtc::SocketAddress &socket) :
        host_(socket.ipaddr()),
        port_(socket.port())
    {
    }

    Socket(const sockaddr_in6 &socket) :
        Socket(socket.sin6_addr, boost::endian::big_to_native(socket.sin6_port))
    {
    }

    Socket(const sockaddr_in &socket) :
        Socket(socket.sin_addr, boost::endian::big_to_native(socket.sin_port))
    {
    }

    Socket(const sockaddr &socket) :
        Socket([&]() -> Socket { switch (socket.sa_family) {
            case AF_INET6:
                return reinterpret_cast<const sockaddr_in6 &>(socket);
            case AF_INET:
                return reinterpret_cast<const sockaddr_in &>(socket);
            default:
                orc_assert_(false, "unsupported address family #" << socket.sa_family);
        } }())
    {
    }

    Socket(const std::string &socket) :
        Socket([&]() {
            rtc::SocketAddress address;
            orc_assert_(address.FromString(socket), socket << " is not a Socket");
            return address;
        }())
    {
    }

    Socket(const char *socket) :
        Socket(std::string(socket))
    {
    }

    template <typename Protocol_>
    operator asio::ip::basic_endpoint<Protocol_>() const {
        return {host_, port_};
    }

    const Host &Host() const {
        return host_;
    }

    uint16_t Port() const {
        return port_;
    }

    bool operator <(const Socket &rhs) const {
        return Tuple() < rhs.Tuple();
    }

    bool operator ==(const Socket &rhs) const {
        return Tuple() == rhs.Tuple();
    }

    bool operator !=(const Socket &rhs) const {
        return Tuple() != rhs.Tuple();
    }
};

inline std::ostream &operator <<(std::ostream &out, const Socket &socket) {
    return out << socket.Host() << ":" << std::dec << socket.Port();
}

class Four {
  private:
    Socket source_;
    Socket destination_;

    std::tuple<const Socket &, const Socket &> Tuple() const {
        return std::tie(source_, destination_);
    }

  public:
    Four(Socket source, Socket destination) :
        source_(source),
        destination_(destination)
    {
    }

    const Socket &Source() const {
        return source_;
    }

    const Socket &Target() const {
        return destination_;
    }

    bool operator <(const Four &rhs) const {
        return Tuple() < rhs.Tuple();
    }

    bool operator ==(const Four &rhs) const {
        return Tuple() == rhs.Tuple();
    }

    bool operator !=(const Four &rhs) const {
        return Tuple() != rhs.Tuple();
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

    std::tuple<uint8_t, const Socket &, const Socket &> Tuple() const {
        return std::tie(protocol_, Source(), Target());
    }

  public:
    Five(uint8_t protocol, Socket source, Socket destination) :
        Four(source, destination),
        protocol_(protocol)
    {
    }

    uint8_t Protocol() const {
        return protocol_;
    }

    bool operator <(const Five &rhs) const {
        return Tuple() < rhs.Tuple();
    }

    bool operator ==(const Five &rhs) const {
        return Tuple() == rhs.Tuple();
    }

    bool operator !=(const Five &rhs) const {
        return Tuple() != rhs.Tuple();
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

    std::tuple<uint8_t, const Socket &> Tuple() const {
        return std::tie(protocol_, *this);
    }

  public:
    template <typename... Args_>
    Three(uint8_t protocol, Args_ &&...args) :
        Socket(std::forward<Args_>(args)...),
        protocol_(protocol)
    {
    }

    uint8_t Protocol() const {
        return protocol_;
    }

    bool operator <(const Three &rhs) const {
        return Tuple() < rhs.Tuple();
    }

    bool operator ==(const Three &rhs) const {
        return Tuple() == rhs.Tuple();
    }

    bool operator !=(const Three &rhs) const {
        return Tuple() != rhs.Tuple();
    }

    Socket Two() const {
        return static_cast<const Socket &>(*this);
    }
};

inline std::ostream &operator <<(std::ostream &out, const Three &three) {
    return out << "[" << three.Protocol() << "|" << static_cast<const Socket &>(three) << "]";
}

}

#endif//ORCHID_SOCKET_HPP
