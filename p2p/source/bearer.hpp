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


#ifndef ORCHID_BEARER_HPP
#define ORCHID_BEARER_HPP

#include <string>
#include <time.h>
#include <jwt/jwt.hpp>

namespace orc {

// XXX: potentially replace cpp-jwt? https://www.233tw.com/php/32480
std::string Bearer(const std::string &aud, const std::string &iss, const std::string &alg, const std::string &kid, const std::string &key, const std::map<std::string, std::string> &claims = {}) {
    jwt::jwt_object object{
        jwt::params::algorithm(alg),
        jwt::params::secret(key),
        jwt::params::headers({{"kid", kid}}),
        jwt::params::payload({{"aud", aud}}),
    };

    object.add_claim("iss", iss);

    for (const auto &[name, value] : claims)
        object.add_claim(name, value);

    const auto now(time(NULL));
    object.add_claim("iat", now);
    object.add_claim("exp", now + 60);

    return object.signature();
}

}

#endif//ORCHID_BEARER_HPP
