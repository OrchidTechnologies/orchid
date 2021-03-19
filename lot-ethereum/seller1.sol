/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2021  The Orchid Authors
*/

/* GNU Affero General Public License, Version 3 {{{ */
/* SPDX-License-Identifier: AGPL-3.0-or-later */
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


pragma solidity 0.7.6;
pragma abicoder v2;

import "./lottery1.sol";

contract OrchidSeller1 {
    OrchidLottery1 private immutable lottery_;
    address private owner_;
    address private manager_;

    constructor(OrchidLottery1 lottery) {
        lottery_ = lottery;
        owner_ = msg.sender;
        manager_ = msg.sender;

        address[] memory recipients;
        lottery.enroll(false, recipients);
    }

    function head() external view returns (address, address) {
        return (owner_, manager_);
    }

    function hand(address owner, address manager) external {
        require(msg.sender == owner_);
        owner_ = owner;
        manager_ = manager;
    }

    function enroll(bool cancel, address[] calldata recipients) external {
        require(msg.sender == owner_);
        return lottery_.enroll(cancel, recipients);
    }


    struct Executor {
        uint256 allowance_;
    }

    mapping(IERC20 => mapping (address => Executor)) private executors_;

    function allow(IERC20 token, uint256 allowance, address[] calldata senders) external {
        require(msg.sender == manager_);
        mapping (address => Executor) storage executors = executors_[token];
        for (uint i = senders.length; i != 0; )
            executors[senders[--i]].allowance_ = allowance;
    }

    function allowed(IERC20 token, address executor) external view returns (uint256) {
        return executors_[token][executor].allowance_;
    }

    function execute_(IERC20 token, address sender, uint256 amount, uint256 retrieve) private {
        if (amount == retrieve)
            return;
        Executor storage executor = executors_[token][sender];
        uint256 allowance = executor.allowance_;
        if (allowance == uint256(-1))
            return;
        if (amount > retrieve)
            amount = amount - retrieve;
        else
            amount = retrieve - amount;
        require(allowance >= amount);
        executor.allowance_ = allowance - amount;
    }


    /*struct Account {
        uint192 refill_;
        uint64 nonce_;
    }*/

    struct Account {
        uint256 packed_;
    }

    mapping(IERC20 => mapping(address => Account)) private accounts_;

    function read(IERC20 token, address signer) public view returns (uint256) {
        return accounts_[token][signer].packed_;
    }

    function read(address signer) external view returns (uint256) {
        return read(IERC20(0), signer);
    }


    function edit_(address sender, address signer, uint8 v, bytes32 r, bytes32 s, uint64 nonce, IERC20 token, uint256 amount, int256 adjust, int256 warn, uint256 retrieve, uint256 refill) private {
        execute_(token, sender, amount, retrieve);
    {
        bytes32 digest; assembly { digest := chainid() }
        digest = keccak256(abi.encodePacked(byte(0x19), byte(0x00), this,
            digest, nonce, token, amount, adjust, warn, retrieve, refill));
        require(signer == ecrecover(digest, v, r, s));
    } {
        Account storage account = accounts_[token][signer];
        uint256 cache = account.packed_;
        require(uint192(refill) == refill);
        require(uint64(cache) == nonce);
        account.packed_ = uint256(refill) << 64 | uint64(nonce + 1);
    }
        if (amount > retrieve)
            lottery_.mark(token, signer, uint64(block.timestamp));
    }

    function edit(address signer, uint8 v, bytes32 r, bytes32 s, uint64 nonce, int256 adjust, int256 warn, uint256 retrieve, uint256 refill) external payable {
        edit_(msg.sender, signer, v, r, s, nonce, IERC20(0), msg.value, adjust, warn, retrieve, refill);
        lottery_.edit{value: msg.value}(signer, adjust, warn, retrieve);

        if (retrieve != 0) {
            (bool success,) = msg.sender.call{value: retrieve}("");
            require(success);
        }
    }


    function gift_(IERC20 token, uint256 amount, address signer, uint256 escrow) private returns (bool) {
    {
        (uint256 balance,) = lottery_.read(token, address(this), signer);
        balance = (balance >> 128) + uint128(balance);
        if (balance > accounts_[token][signer].packed_ >> 64)
            return false;
    }

        lottery_.mark(token, signer, uint64(block.timestamp));

        require(escrow <= amount);
        require(int256(escrow) >= 0);
        lottery_.edit{value: amount}(signer, int256(escrow), 0, 0);

        return true;
    }

    function gift(address signer, uint256 escrow) external payable {
        execute_(IERC20(0), msg.sender, msg.value, 0);
        require(gift_(IERC20(0), msg.value, signer, escrow));
    }


    struct Gift {
        address signer;
        uint256 amount;
        uint256 escrow;
    }

    function giftv(Gift[] calldata gifts) external payable {
        require(msg.sender == manager_);

        for (uint i = gifts.length; i != 0; ) {
            Gift calldata temp = gifts[--i];
            gift_(IERC20(0), temp.amount, temp.signer, temp.escrow);
        }
    }
}
