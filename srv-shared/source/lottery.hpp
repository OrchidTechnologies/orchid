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
#include "locked.hpp"
#include "signed.hpp"
#include "ticket.hpp"
#include "valve.hpp"

namespace orc {

struct Pot {
    uint256_t amount_ = 0;
    uint256_t escrow_ = 0;
    uint256_t warned_ = 0;

    uint256_t usable() const {
        return std::min((escrow_ < warned_ ? 0 : escrow_ - warned_) / 2, amount_);
    }
};

std::ostream &operator <<(std::ostream &out, const Pot &pot);

class Lottery :
    public Valve
{
  protected:
    struct Locked_ {
        std::map<Bytes32, std::pair<Pot, uint64_t>> pots_;
    }; Locked<Locked_> locked_;

    Bytes32 Hash(const Address &signer, const Address &funder) {
        // XXX: this only makes sense for lottery1, but it works
        return HashK(Tie(Address(0), funder, signer));
    }

    virtual task<uint64_t> Height() = 0;
    virtual task<Pot> Read(uint64_t height, const Address &signer, const Address &funder, const Address &recipient) = 0;
    virtual task<void> Scan(uint64_t begin, uint64_t end) = 0;

  public:
    Lottery(const char *type) :
        Valve(type)
    {
    }

    void Open();

    task<uint256_t> Check(const Address &signer, const Address &funder, const Address &recipient);
};

inline uint256_t Convert(const Float &balance) {
    return Complement(checked_int256_t(balance));
}

}

#endif//ORCHID_LOTTERY_HPP
