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

contract OrchidSeller {
    OrchidLottery1 private immutable lottery_;
    address private owner_;

    constructor(OrchidLottery1 lottery, address owner) {
        lottery_ = lottery;
        owner_ = owner;
    }

    function head() external view returns (address) {
        return owner_;
    }

    function hand(address owner) external {
        require(msg.sender == owner_);
        owner_ = owner;
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
        require(msg.sender == owner_);
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
        uint128 refill_;
        uint64 zero_;
        uint64 nonce_;
    }*/

    struct Account {
        uint256 packed_;
    }

    mapping(address => Account) private accounts_;

    function read(address signer) external view returns (uint256) {
        return accounts_[signer].packed_;
    }


    function edit_(address sender, address signer, uint8 v, bytes32 r, bytes32 s, uint64 nonce, IERC20 token, uint256 amount, int256 adjust, int256 warn, uint256 retrieve, uint128 refill) private {
        execute_(token, sender, amount, retrieve);
    {
        bytes32 digest; assembly { digest := chainid() }
        digest = keccak256(abi.encodePacked(byte(0x19), byte(0x00), this,
            digest, nonce, token, amount, adjust, warn, retrieve, refill));
        require(signer == ecrecover(digest, v, r, s));
    } {
        Account storage account = accounts_[signer];
        uint256 cache = account.packed_;
        require(uint64(cache) == nonce);
        account.packed_ = uint256(refill) << 128 | uint64(nonce + 1);
    }
        if (amount > retrieve)
            lottery_.mark(token, signer, uint64(block.timestamp));
    }

    function edit(address signer, uint8 v, bytes32 r, bytes32 s, uint64 nonce, int256 adjust, int256 warn, uint256 retrieve, uint128 refill) external payable {
        edit_(msg.sender, signer, v, r, s, nonce, IERC20(0), msg.value, adjust, warn, retrieve, refill);
        lottery_.edit{value: msg.value}(signer, adjust, warn, retrieve);

        if (retrieve != 0) {
            (bool success,) = msg.sender.call{value: retrieve}("");
            require(success);
        }
    }


    function gift(address signer, uint256 escrow) external payable {
        execute_(IERC20(0), msg.sender, msg.value, 0);
    {
        (uint256 balance,) = lottery_.read(IERC20(0), address(this), signer);
        balance = (balance >> 128) + uint128(balance);
        require(balance <= accounts_[signer].packed_ >> 128);
    }
        lottery_.mark(IERC20(0), signer, uint64(block.timestamp));

        require(escrow <= msg.value);
        require(int256(escrow) >= 0);
        lottery_.edit{value: msg.value}(signer, int256(escrow), 0, 0);
    }
}
