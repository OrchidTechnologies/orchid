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

#include <string>

#include "endpoint.hpp"
#include "local.hpp"
#include "locator.hpp"

namespace orc {

class Cashier {
  private:
    Endpoint endpoint_;
    Address lottery_;
    uint256_t price_;
    Address personal_;
    std::string password_;

  public:
    Cashier(Locator rpc, Address lottery, uint256_t price, Address personal, std::string password) :
        endpoint_(GetLocal(), std::move(rpc)),
        lottery_(std::move(lottery)),
        price_(std::move(price)),
        personal_(std::move(personal)),
        password_(std::move(password))
    {
    }

    uint256_t Price() const {
        return price_;
    }

    template <typename Selector_, typename... Args_>
    task<void> Send(Selector_ &selector, Args_ &&...args) {
        co_await selector.Send(endpoint_, personal_, password_, lottery_, std::forward<Args_>(args)...);
    }
};

}

#endif//ORCHID_CASHIER_HPP
