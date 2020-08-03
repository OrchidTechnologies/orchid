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


#ifndef ORCHID_MARKET_HPP
#define ORCHID_MARKET_HPP

#include "float.hpp"
#include "signed.hpp"
#include "updated.hpp"

namespace orc {

struct Fiat;
class Gauge;
class Origin;

class Market {
  private:
    const S<Updated<Fiat>> fiat_;
    const S<Gauge> gauge_;

  public:
    Market(unsigned milliseconds, const S<Origin> &origin, std::string currency);

    checked_int256_t Convert(const Float &balance) const;
    std::pair<Float, uint256_t> Credit(const uint256_t &now, const uint256_t &start, const uint128_t &range, const uint128_t &amount, const uint256_t &gas) const;
};

}

#endif//ORCHID_MARKET_HPP
