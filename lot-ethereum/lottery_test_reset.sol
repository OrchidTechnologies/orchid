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


pragma solidity ^0.5.12;

import "lottery.sol";

contract TestResetOrchidLottery is OrchidLottery
{
    constructor(IERC20 token) public OrchidLottery(token) {}

    // Remove all signers for this funder and return their balance and escrow to the target address.
    function reset(address payable target) external {
        address funder = msg.sender;
        Lottery storage lottery = lotteries_[funder];
        uint count = lottery.keys_.length;
        for (uint256 i = 0; i != count; ++i) {
            address signer = lottery.keys_[count-i-1];
            Pot storage pot = lottery.pots_[signer];
             // pull
            uint128 total = pot.amount_ + pot.escrow_;
            if (total != 0) {
                pot.amount_ = 0;
                pot.escrow_ = 0;
                token_.transfer(target, total);
            }
             // kill
            --lottery.keys_.length;
            delete lottery.pots_[signer];
        }
    }
}
