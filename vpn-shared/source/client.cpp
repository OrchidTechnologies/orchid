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


#include <rtc_base/openssl_identity.h>

#include "channel.hpp"
#include "client.hpp"
#include "locator.hpp"

namespace orc {

void Server::Land(Pipe *pipe, const Buffer &data) {
    return Pump::Land(data);
}

Server::Server(BufferDrain *drain, const std::string &pot, U<rtc::SSLFingerprint> remote) :
    Pump(drain),
    pot_(pot),
    remote_(std::move(remote)),
    local_(Certify())
{
}

task<void> Server::Connect(const S<Origin> &origin, const std::string &url) {
    auto verify([this](const rtc::OpenSSLCertificate &certificate) -> bool {
        return *remote_ == *rtc::SSLFingerprint::Create(remote_->algorithm, certificate);
    });

    auto sunk(Wire());

    socket_ = co_await Channel::Wire(sunk, [&]() {
        Configuration configuration;
        return configuration;
    }(), [&](std::string offer) -> task<std::string> {
        auto answer(co_await origin->Request("POST", Locator::Parse(url), {}, offer, verify));
        if (true || Verbose) {
            Log() << "Offer: " << offer << std::endl;
            Log() << "Answer: " << answer << std::endl;
        }
        co_return answer;
    });
}

}
