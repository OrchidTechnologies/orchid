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


pragma solidity 0.7.2;
pragma experimental ABIEncoderV2;

import "lot-ethereum/lottery1.sol";


contract PACFunder1 {

    OrchidLottery1 internal lottery_;
    address owner_;

    constructor(OrchidLottery1 lottery) public {
        lottery_ = lottery;
        owner_   = msg.sender;
    }

    function bind(bool allow, address[] calldata recipients) external {
        require(msg.sender == owner_);
        lottery_.bind(allow, recipients);
    }

    function gift(address signer) external payable {
        lottery_.gift(address(this), signer);
    }

    function move(uint8 v, bytes32 r, bytes32 s, uint256 adjust_retrieve, uint256 escrow_amount, uint256 unlock_warned) external payable {

        address funder   = address(this);
        uint256 retrieve = uint128(adjust_retrieve);
        require(retrieve == 0);

        bytes32 args; assembly { args := chainid() }
        args = keccak256(abi.encode(args, funder, adjust_retrieve, escrow_amount, unlock_warned));
        address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", args)), v, r, s);
        require(signer != address(0));

        Pot storage pot = ORC_POT(funder, signer);
        require(pot.escrow_amount_ == escrow_amount);
        require(pot.unlock_warned_ == unlock_warned);

        lottery_.move(signer, adjust_retrieve);
    }

    function warn(uint128 warned, uint256 escrow_amount, uint256 unlock_warned) external {

        address funder   = address(this);

        bytes32 args; assembly { args := chainid() }
        args = keccak256(abi.encode(args, funder, warned, escrow_amount, unlock_warned));
        address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", args)), v, r, s);
        require(signer != address(0));

        Pot storage pot = ORC_POT(funder, signer);
        require(pot.escrow_amount_ == escrow_amount);
        require(pot.unlock_warned_ == unlock_warned);

        lottery_.warn(signer, warned);
    }

}
