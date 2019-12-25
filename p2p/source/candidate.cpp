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


#include <regex>

#include <p2p/base/ice_transport_internal.h>

#include "peer.hpp"

namespace orc {

task<cricket::Candidate> Peer::Candidate() {
    const auto sctp(co_await Post([&]() -> rtc::scoped_refptr<webrtc::SctpTransportInterface> {
        return peer_->GetSctpTransport();
    }));

    orc_assert(sctp != nullptr);

    co_return co_await Post([&]() -> cricket::Candidate {
        const auto dtls(sctp->dtls_transport());
        orc_assert(dtls != nullptr);
        const auto ice(dtls->ice_transport());
        orc_assert(ice != nullptr);
        const auto internal(ice->internal());
        orc_assert(internal != nullptr);
        const auto connection(internal->selected_connection());
        orc_assert(connection != nullptr);
        return connection->remote_candidate();
    }, origin_->Thread());
}

std::string Strip(const std::string &sdp) {
    static const std::regex re("\r?\na=candidate:[^\r\n]*");
    return std::regex_replace(sdp, re, "");
}

}
