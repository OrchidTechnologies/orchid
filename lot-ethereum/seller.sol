/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2020  The Orchid Authors
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


    mapping(address => uint256) private executors_;

    function allow(uint256 allowance, address[] calldata senders) external {
        require(msg.sender == owner_);
        for (uint i = senders.length; i != 0; )
            executors_[senders[--i]] = allowance;
    }

    function allowed(address executor) external view returns (uint256) {
        return executors_[executor];
    }


    struct Account {
        uint256 nonce_;
    }

    mapping(address => Account) private accounts_;

    function next(address signer) external view returns (uint256) {
        return accounts_[signer].nonce_;
    }

    function next_(address sender, uint8 v, bytes32 r, bytes32 s, uint256 nonce, IERC20 token, uint256 amount, int256 adjust, int256 lock, uint256 retrieve) private returns (address) {
        require(amount == 0 && retrieve == 0 || executors_[sender] != 0);

        bytes32 digest; assembly { digest := chainid() }
        digest = keccak256(abi.encodePacked(byte(0x19), byte(0x00), this,
            digest, nonce, token, amount, adjust, lock, retrieve));
        address signer = ecrecover(digest, v, r, s);

        Account storage account = accounts_[signer];
        require(account.nonce_ == nonce);
        account.nonce_ = nonce + 1;

        if (amount > retrieve)
            lottery_.mark(token, signer);

        return signer;
    }


    function edit(uint8 v, bytes32 r, bytes32 s, uint256 nonce, int256 adjust, int256 lock, uint256 retrieve) external payable {
        address signer = next_(msg.sender, v, r, s, nonce, IERC20(0), msg.value, adjust, lock, retrieve);
        lottery_.edit{value: msg.value}(signer, adjust, lock, retrieve);

        if (retrieve != 0) {
            (bool success,) = msg.sender.call{value: retrieve}("");
            require(success);
        }
    }


    function gift(address signer, uint256 escrow) external payable {
        require(executors_[msg.sender] != 0);
        require(escrow <= msg.value);
        require(int256(escrow) >= 0);
        return lottery_.edit{value: msg.value}(signer, int256(escrow), 0, 0);
    }
}
