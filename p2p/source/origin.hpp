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


#ifndef ORCHID_ORIGIN_HPP
#define ORCHID_ORIGIN_HPP

#include "break.hpp"
#include "http.hpp"
#include "link.hpp"
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

class Origin :
    public Valve
{
  private:
    U<rtc::NetworkManager> manager_;

  public:
    Origin(U<rtc::NetworkManager> manager);
    ~Origin() override;

    virtual Host Host() = 0;

    virtual rtc::Thread *Thread() = 0;
    virtual rtc::BasicPacketSocketFactory &Factory() = 0;
    U<cricket::PortAllocator> Allocator();

    virtual task<Socket> Associate(Sunk<> *sunk, const std::string &host, const std::string &port) = 0;
    virtual task<Socket> Connect(U<Stream> &stream, const std::string &host, const std::string &port) = 0;
    virtual task<Socket> Unlid(Sunk<Opening, BufferSewer> *sunk) = 0;

    task<std::string> Request(const std::string &method, const Locator &locator, const std::map<std::string, std::string> &headers, const std::string &data, const std::function<bool (const rtc::OpenSSLCertificate &)> &verify = nullptr);
};

}

#endif//ORCHID_ORIGIN_HPP
