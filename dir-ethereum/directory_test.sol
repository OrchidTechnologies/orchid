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


pragma solidity 0.5.13;

import "directory.sol";


contract TestOrchidDirectory is OrchidDirectory
{

    constructor(IERC20 token) public OrchidDirectory(token) {}

    function set(IERC20 token) public {
        token_ = token;
    }

    function get_token(uint256)     public view returns (address)    { return address(token_); }


    function get_amount(address stakee) public view returns (uint256)
    {
        address staker  = msg.sender;
        bytes32 key     = keccak256(abi.encodePacked(staker, stakee));
        //bytes32 key     = name(staker, stakee);
        Stake storage stake = stakes_[key];
        return stake.amount_;
    }
}
