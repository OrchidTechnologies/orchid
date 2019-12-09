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


#ifndef ORCHID_CASHIER_HPP
#define ORCHID_CASHIER_HPP

#include <mutex>
#include <string>

#include "coinbase.hpp"
#include "endpoint.hpp"
#include "local.hpp"
#include "locked.hpp"
#include "locator.hpp"

namespace orc {

class Cashier {
  private:
    const Endpoint endpoint_;

    const Float price_;
    const std::string currency_;

    const Address personal_;
    const std::string password_;

    const Address lottery_;
    const uint256_t chain_;
    const Address recipient_;

    struct Locked_ {
        Float eth_ = 0;
        Float oxt_ = 0;
    };

    Locked<Locked_> locked_;

    task<void> Update();

  public:
    Cashier(Endpoint endpoint, const Float &price, std::string currency, const Address &personal, std::string password, const Address &lottery, const uint256_t &chain, const Address &recipient);

    auto Tuple() const {
        return std::tie(lottery_, chain_, recipient_);
    }

    Float Bill(size_t size) const;
    checked_int256_t Convert(const Float &balance) const;

    Float Credit(const uint256_t &now, const uint256_t &start, const uint256_t &until, const uint256_t &amount, const uint256_t &gas) const;
    task<void> Check(const Address &signer, const Address &funder, const uint128_t &amount, const Address &recipient, const Buffer &receipt);

    template <typename Selector_, typename... Args_>
    void Send(Selector_ &selector, const uint256_t &gas, Args_ &&...args) {
        Spawn([=]() mutable -> task<void> {
            co_await selector.Send(endpoint_, personal_, password_, lottery_, gas, 10*Gwei, std::forward<Args_>(args)...);
        });
    }
};

}

#endif//ORCHID_CASHIER_HPP
