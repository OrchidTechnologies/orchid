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


#ifndef ORCHID_ENDPOINT_HPP
#define ORCHID_ENDPOINT_HPP

#include "json.hpp"
#include "locator.hpp"
#include "origin.hpp"

namespace orc {

class Endpoint {
  private:
    const Locator locator_;
    const S<Origin> origin_;

  public:
    // XXX: default origin to Local
    Endpoint(Locator locator, S<Origin> origin) :
        locator_(std::move(locator)),
        origin_(std::move(origin))
    {
    }

    operator const Locator &() const {
        return locator_;
    }

    // XXX: remove this once Network takes a Market
    const S<Origin> &hack() const {
        return origin_;
    }

    task<Json::Value> operator ()(const std::string &method, Argument args) const;
};

}

#endif//ORCHID_ENDPOINT_HPP
