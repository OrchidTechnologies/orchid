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


#include "connection.hpp"
#include "interface.hpp"
#include "manager.hpp"
#include "naive.hpp"
#include "specific.hpp"

namespace orc {

Naive::Naive() :
    Base(typeid(*this).name(), nullptr)
{
}

class Host Naive::Host() {
    orc_assert(false);
}

rtc::Thread &Naive::Thread() {
    orc_assert(false);
}

rtc::BasicPacketSocketFactory &Naive::Factory() {
    orc_assert(false);
}

task<void> Naive::Associate(BufferSunk &sunk, const Socket &endpoint) {
    orc_assert(false);
}

task<Socket> Naive::Unlid(Sunk<BufferSewer, Opening> &sunk) {
    orc_assert(false);
}

task<U<Stream>> Naive::Connect(const Socket &endpoint) {
    auto connection(std::make_unique<Connection>(Context()));
    // XXX: this is only temporarily--and, even then, only barely--safe here
    orc_assert(pthread_setspecific(protect_, __FUNCTION__) == 0);
    //Specific specific(protect_, __FUNCTION__);
    // NOLINTNEXTLINE (clang-analyzer-optin.cplusplus.VirtualCall)
    co_await connection->Open(endpoint);
    co_return connection;
}

}
