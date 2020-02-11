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

import "lot-ethereum/lottery.sol";


contract PACFunder {

    OrchidLottery internal lottery_;
    address owner_;
    mapping(bytes32 => bool) claimed_;


    constructor(OrchidLottery lottery) public {
        lottery_ = lottery;
        owner_   = msg.sender;
    }

    function kill(address signer) external { require(msg.sender == owner_); lottery_.kill(signer); }
    function push(address signer, uint128 total, uint128 escrow) external { require(msg.sender == owner_); lottery_.push(signer,total,escrow); }
    function move(address signer, uint128 amount) external { require(msg.sender == owner_); lottery_.move(signer,amount); }
    function burn(address signer, uint128 escrow) external { require(msg.sender == owner_); lottery_.burn(signer,escrow); }
    function bind(address signer, OrchidVerifier verify, bytes calldata shared) external { require(msg.sender == owner_); lottery_.bind(signer,verify,shared); }
    //function give(address funder, address payable recipient, uint128 amount, bytes calldata receipt) external { }
    function warn(address signer) external { require(msg.sender == owner_); lottery_.warn(signer); }
    function lock(address signer) external { require(msg.sender == owner_); lottery_.lock(signer); }
    function pull(address signer, address payable target, bool autolock, uint128 amount, uint128 escrow) external { require(msg.sender == owner_); lottery_.pull(signer,target,autolock,amount,escrow); }
    function yank(address signer, address payable target, bool autolock) external { require(msg.sender == owner_); lottery_.yank(signer,target,autolock); }
    
    function bind_push(address signer, OrchidVerifier verify, bytes memory shared, uint128 total, uint128 escrow) private {
        require(msg.sender == owner_);
    	lottery_.bind(signer, verify, shared);
    	lottery_.push(signer, total, escrow);
    }

    event Fund(bytes32 indexed receipt, address indexed signer, uint128 total, uint128 escrow);
    
    function fund(bytes32 receipt, address signer, OrchidVerifier verify, bytes calldata shared, uint128 total, uint128 escrow) external {
        require(msg.sender == owner_);
        require(claimed_[receipt] == false);
        bind_push(signer,verify,shared,total,escrow);
        claimed_[receipt] = true;
        emit Fund(receipt,signer,total,escrow);
    }
    
}
