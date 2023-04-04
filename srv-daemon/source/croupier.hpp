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


#ifndef ORCHID_CROUPIER_HPP
#define ORCHID_CROUPIER_HPP

#include <map>

#include "lottery0.hpp"
#include "lottery1.hpp"
#include "time.hpp"
#include "updated.hpp"

namespace orc {

class Croupier {
  private:
    const Address recipient_;
    const S<Executor> executor_;

    const S<Lottery0> lottery0_;
    const std::map<uint256_t, S<Lottery1>> lotteries1_;

  public:
    Croupier(Address recipient, S<Executor> executor, S<Lottery0> lottery0, std::map<uint256_t, S<Lottery1>> lotteries1);

    // XXX this is because Server is processing tickets currently
    const S<Executor> &hack() {
        return executor_;
    }

    const Address &Recipient() {
        return recipient_;
    }

    const S<Lottery0> &Find0(const Address &contract, const uint256_t &chain, const Address &recipient) {
        orc_assert(recipient == recipient_);
        orc_assert(std::tie(contract, chain) == lottery0_->Tuple());
        return lottery0_;
    }

    const S<Lottery1> &Find1(const Address &contract, const uint256_t &chain) {
        const auto lottery(lotteries1_.find(chain));
        orc_assert(lottery != lotteries1_.end());
        orc_assert(lottery->second->Contract() == contract);
        return lottery->second;
    }

    Builder Invoice(uint64_t serial, const Float &balance, const Bytes32 &reveal) const {
        Builder builder;
        builder += Tie(Command(Stamp_, Monotonic()));
        builder += Tie(lottery0_->Invoice(serial, balance, HashK(reveal), recipient_));
#if 0
        for (const auto &[chain, lottery1] : lotteries1_)
            builder += lottery1->Invoice();
#endif
        return builder;
    }
};

}

#endif//ORCHID_CROUPIER_HPP
