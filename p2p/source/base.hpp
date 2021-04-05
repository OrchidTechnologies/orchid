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


#ifndef ORCHID_BASE_HPP
#define ORCHID_BASE_HPP

#include <cppcoro/async_mutex.hpp>
#include <cppcoro/shared_task.hpp>

#include <rtc_base/openssl_certificate.h>

#include "cache.hpp"
#include "dns.hpp"
#include "fetcher.hpp"
#include "link.hpp"
#include "locator.hpp"
#include "reader.hpp"
#include "sewer.hpp"
#include "socket.hpp"
#include "task.hpp"

namespace cricket {
    class PortAllocator;
}

namespace rtc {
    class BasicPacketSocketFactory;
    class NetworkManager;
    class Thread;
}

namespace orc {

class Base :
    public Valve
{
  private:
    const U<rtc::NetworkManager> manager_;

    static cppcoro::shared_task<std::string> Resolve_(Base &base, const std::string &host);
    Cache<cppcoro::shared_task<std::string>, Base &, std::string, &Resolve_> cache_;

    std::multimap<Origin, U<Fetcher>> fetchers_;

  public:
    Base(const char *type, U<rtc::NetworkManager> manager);
    ~Base() override;

    virtual Host Host() = 0;

    virtual rtc::Thread &Thread() = 0;
    virtual rtc::BasicPacketSocketFactory &Factory() = 0;
    U<cricket::PortAllocator> Allocator();

    virtual task<void> Associate(BufferSunk &sunk, const Socket &endpoint) = 0;
    virtual task<Socket> Unlid(Sunk<BufferSewer, Opening> &sunk) = 0;
    virtual task<U<Stream>> Connect(const Socket &endpoint) = 0;

    task<Response> Fetch(const std::string &method, const Locator &locator, const std::map<std::string, std::string> &headers, const std::string &data, const std::function<bool (const std::list<const rtc::OpenSSLCertificate> &)> &verify = nullptr);

    task<std::vector<asio::ip::tcp::endpoint>> Resolve(const std::string &host, const std::string &port);
};

}

#endif//ORCHID_BASE_HPP
