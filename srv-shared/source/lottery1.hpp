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


#ifndef ORCHID_LOTTERY1_HPP
#define ORCHID_LOTTERY1_HPP

#include <map>
#include <string>

#include "executor.hpp"
#include "event.hpp"
#include "local.hpp"
#include "locked.hpp"
#include "locator.hpp"
#include "lottery.hpp"
#include "market.hpp"
#include "protocol.hpp"
#include "sleep.hpp"
#include "signed.hpp"
#include "spawn.hpp"
#include "updated.hpp"

namespace orc {

class Lottery1 :
    public Lottery
{
  private:
    const Market market_;
    const Address contract_;

  protected:
    task<uint128_t> Check_(const Address &signer, const Address &funder, const Address &recipient) override;

  public:
    Lottery1(Market market, Address contract);
    ~Lottery1() override = default;

    void Open(S<Base> base, Locator locator);
    task<void> Shut() noexcept override;

    const Address &Contract() const {
        return contract_;
    }

    std::pair<Float, uint256_t> Credit(const uint256_t &now, const uint256_t &start, const uint128_t &range, const uint128_t &amount, const uint128_t &ratio, const uint64_t &gas) const;

    void Send(const S<Executor> &executor, const Address &recipient, const Payment1 &payment) {
        static Selector<void,
            Address /*token*/,
            Address /*recipient*/,
            std::vector<Payment1> /*payments*/,
            std::vector<Bytes32> /*refunds*/
        > claim("claim");

        Spawn([=]() mutable noexcept -> task<void> {
            for (;;) {
                orc_ignore({
                    co_await executor->Send(*market_.chain_, {}, contract_, 0, claim({}, recipient, {payment}, {}));
                    break;
                });

                // XXX: I should dump these to a disk queue as they are worth "real money"
                // XXX: that same disk queue should maybe be in charge of the old tickets?
                co_await Sleep(5000);
            }
        }, __FUNCTION__);
    }
};

}

#endif//ORCHID_LOTTERY1_HPP
