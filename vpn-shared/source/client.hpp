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


#ifndef ORCHID_CLIENT_HPP
#define ORCHID_CLIENT_HPP

#include <rtc_base/rtc_certificate.h>
#include <rtc_base/ssl_fingerprint.h>

#include "bond.hpp"
#include "origin.hpp"

namespace orc {

class Client :
    public Bonded,
    public Pump
{
  public:
    std::string pot_;
    U<rtc::SSLFingerprint> remote_;
    rtc::scoped_refptr<rtc::RTCCertificate> local_;

    Socket socket_;

  protected:
    void Land(Pipe *pipe, const Buffer &data) override;

  public:
    Client(BufferDrain *drain, const std::string &pot, U<rtc::SSLFingerprint> remote);

    task<void> Open(const S<Origin> &origin, const std::string &url);
    task<void> Shut() override;

    task<void> Send(const Buffer &data) override;
};

}

#endif//ORCHID_CLIENT_HPP
