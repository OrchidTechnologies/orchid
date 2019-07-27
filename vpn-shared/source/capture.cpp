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


#include "capture.hpp"
#include "transport.hpp"

namespace orc {

void Capture::Land(const Buffer &data) {
    //Log() << "\e[35;1mSEND " << data.size() << " " << data << "\e[0m" << std::endl;

    // analyze/monitor data

    if (sync_)
        sync_->Send(data);
}

void Capture::Stop(const std::string &error) {
    orc_insist(false);
}

task<void> Capture::Send(const Buffer &data) {
    //Log() << "\e[33;1mRECV " << data.size() << " " << data << "\e[0m" << std::endl;
    co_return co_await Inner()->Send(data);
}

Capture::Capture() {
}

Capture::~Capture() = default;

task<void> Capture::Start(std::string ovpnfile, std::string username, std::string password) {
    auto origin(co_await Setup());
    sync_ = co_await Connect(this, std::move(origin), std::move(ovpnfile), std::move(username), std::move(password));
}

}
