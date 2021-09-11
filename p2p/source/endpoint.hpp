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

#include "base.hpp"
#include "locator.hpp"
#include "notation.hpp"

namespace orc {

class Endpoint {
  private:
    const Locator locator_;
    const S<Base> base_;

  public:
    // XXX: default base to Local
    Endpoint(Locator locator, S<Base> base) :
        locator_(std::move(locator)),
        base_(std::move(base))
    {
    }

    operator const Locator &() const {
        return locator_;
    }

    // XXX: remove this once Network takes a Market
    const S<Base> &hack() const {
        return base_;
    }

    task<Json::Value> operator ()(const std::string &method, Argument args) const;

    task<boost::json::value> Call(const std::string &method, Argument args) const {
        co_return Reparse(co_await operator ()(method, std::move(args)));
    }
};

}

#endif//ORCHID_ENDPOINT_HPP
