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


#ifndef ORCHID_CONFIGURATION_HPP
#define ORCHID_CONFIGURATION_HPP

#include <string>
#include <vector>

#include "rtc_base/rtc_certificate.h"

namespace orc {

struct Configuration final {
    rtc::scoped_refptr<rtc::RTCCertificate> tls_;
    std::vector<std::string> ice_;
};

rtc::scoped_refptr<rtc::RTCCertificate> Certify();

}

#endif//ORCHID_CONFIGURATION_HPP
