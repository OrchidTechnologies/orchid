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


#ifndef ORCHID_LOTTERY0_HPP
#define ORCHID_LOTTERY0_HPP

#include <map>
#include <string>

#include "currency.hpp"
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
#include "time.hpp"
#include "token.hpp"
#include "updated.hpp"

namespace orc {

class Lottery0 :
    public Lottery
{
  private:
    const Token token_;
    const Address contract_;

  protected:
    task<uint64_t> Height() override;
    task<Pot> Read(uint64_t height, const Address &signer, const Address &funder, const Address &recipient) override;
    task<void> Scan(uint64_t begin, uint64_t end) override;

  public:
    Lottery0(Token token, Address contract);
    ~Lottery0() override = default;

    task<void> Shut() noexcept override;

    auto Tuple() const {
        return std::tie(contract_, token_.market_.chain_->operator const uint256_t &());
    }

    Beam Invoice(uint64_t serial, const Float &dollars, const Bytes32 &commit, const Address &recipient) const {
        return Beam(Tie(Command(Invoice0_, serial, Convert(dollars / token_.currency_.dollars_() * Two128), Tuple(), recipient, commit)));
    }

    std::pair<Float, uint256_t> Credit(const uint256_t &now, const uint256_t &start, const uint128_t &range, const uint128_t &amount, const uint128_t &ratio, const uint64_t &gas) const;

    template <typename... Args_>
    void Send(const S<Executor> &executor, Args_ &&...args) {
        static Selector<void,
            Bytes32 /*reveal*/, Bytes32 /*commit*/,
            uint256_t /*issued*/, Bytes32 /*nonce*/,
            uint8_t /*v*/, Bytes32 /*r*/, Bytes32 /*s*/,
            uint128_t /*amount*/, uint128_t /*ratio*/,
            uint256_t /*start*/, uint128_t /*range*/,
            Address /*funder*/, Address /*recipient*/,
            Bytes /*receipt*/, std::vector<Bytes32> /*old*/
        > grab("grab");

        Spawn([=]() mutable noexcept -> task<void> {
            for (;;) {
                orc_ignore({
                    co_await executor->Send(*token_.market_.chain_, {}, contract_, 0, grab(std::forward<Args_>(args)...));
                    break;
                });

                // XXX: I should dump these to a disk queue as they are worth "real money"
                // XXX: that same disk queue should maybe be in charge of the old tickets?
                co_await Sleep(5000);

                const auto refs(std::make_tuple(std::ref(args)...));
                if (std::get<9>(refs) + std::get<10>(refs) <= Timestamp())
                    break;
            }
        }, __FUNCTION__);
    }
};

}

#endif//ORCHID_LOTTERY0_HPP
