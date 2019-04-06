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


#ifndef ORCHID_EXTERNAL_HPP
#define ORCHID_EXTERNAL_HPP

#ifndef OPENVPN_EXTERN
#define OPENVPN_EXTERN extern
#ifdef __cplusplus
#include <OpenVPNAdapter/OpenVPNClient.h>

struct OpenVPNClient_ :
    OpenVPNClient
{
    virtual TransportClientFactory *new_transport_factory(const openvpn::ExternalTransport::Config &config);

    using OpenVPNClient::OpenVPNClient;
};

#define OpenVPNClient OpenVPNClient_
#endif
#endif

#endif//ORCHID_EXTERNAL_HPP
