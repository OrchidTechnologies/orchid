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


#ifndef ORCHID_ETHEREUM_HPP
#define ORCHID_ETHEREUM_HPP

#include "chain.hpp"

namespace orc {

// XXX: this class is a stub; users access chain_ directly for now
class Ethereum {
  public:
    const S<Chain> chain_;

  public:
    Ethereum(S<Chain> chain) :
        chain_(std::move(chain))
    {
    }

    static task<S<Ethereum>> New(const S<Base> &base, const Locator &locator);
    static task<S<Ethereum>> New(const S<Base> &base, const std::vector<std::string> &chains);

    operator const Chain &() const {
        return *chain_;
    }

    const Chain &operator ->() const {
        return *chain_;
    }
};

}

#endif//ORCHID_ETHEREUM_HPP
