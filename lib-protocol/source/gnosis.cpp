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


#include "gnosis.hpp"

namespace orc {

GnosisExecutor::GnosisExecutor(Address address, S<Executor> executor) :
    address_(std::move(address)),
    executor_(std::move(executor))
{
}

GnosisExecutor::operator Address() const {
    return address_;
}

task<Signature> GnosisExecutor::operator ()(const Chain &chain, const Buffer &data) const {
    orc_assert(false);
}

task<Bytes32> GnosisExecutor::Send(const Chain &chain, Execution execution, const std::optional<Address> &target, const uint256_t &value, const Buffer &data) const {
    static Selector<void, Address, uint256_t, Bytes> submitTransaction("submitTransaction");
    orc_assert_(target, "unsupported multisig contract deployment");
    orc_assert_(*target != Address(), "unsupported multisig send to address 0");
    co_return co_await executor_->Send(chain, std::move(execution), address_, 0, submitTransaction(*target, value, Bytes(data)));
}

}
