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


#include "ethereum.hpp"

namespace orc {

dev::p2p::Host &Ethereum() {
    dev::p2p::NetworkConfig config;
    dev::bytes saved;

    static dev::p2p::Host host("orchid/0.9", config, &saved);
    host.start();

    for (auto const &peer : dev::p2p::Host::pocHosts()) {
        auto endpoint(dev::p2p::Network::resolveHost(peer.second));
        host.requirePeer(peer.first, dev::p2p::NodeIPEndpoint(endpoint.address(), endpoint.port(), endpoint.port()));
    }

    return host;
}

}
