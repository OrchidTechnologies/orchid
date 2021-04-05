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


#ifndef ORCHID_LOTTERY_HPP
#define ORCHID_LOTTERY_HPP

#include <map>
#include <optional>

#include "float.hpp"
#include "integer.hpp"
#include "signed.hpp"
#include "ticket.hpp"
#include "valve.hpp"

namespace orc {

typedef std::tuple<Address, Address> Pot;

class Lottery :
    public Valve
{
  protected:
    // XXX: locking
    std::map<Pot, std::optional<std::pair<uint128_t, uint64_t>>> cache_;

    virtual task<uint128_t> Check_(const Address &signer, const Address &funder, const Address &recipient) = 0;

  public:
    Lottery(const char *type) :
        Valve(type)
    {
    }

    task<uint128_t> Check(const Address &signer, const Address &funder, const Address &recipient);
};

inline uint256_t Convert(const Float &balance) {
    return Complement(checked_int256_t(balance));
}

}

#endif//ORCHID_LOTTERY_HPP
