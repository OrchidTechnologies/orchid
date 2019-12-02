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
#include "locator.hpp"

namespace orc {

class Cashier {
  private:
    Endpoint endpoint_;
    const Address lottery_;
    const Address personal_;
    const std::string password_;
    const Address recipient_;

    mutable std::mutex mutex_;
    uint256_t price_;

    task<void> Update(cpp_dec_float_50 price, const std::string &currency);

  public:
    Cashier(Endpoint endpoint, Address lottery, const std::string &price, const std::string &currency, Address personal, std::string password, Address recipient);

    uint256_t Bill(size_t size) const {
        std::unique_lock<std::mutex> lock(mutex_);
        return price_ * size;
    }

    Address Recipient() const {
        return recipient_;
    }

    template <typename Selector_, typename... Args_>
    task<void> Send(Selector_ &selector, Args_ &&...args) {
        co_await selector.Send(endpoint_, personal_, password_, lottery_, std::forward<Args_>(args)...);
    }
};

}

#endif//ORCHID_CASHIER_HPP
