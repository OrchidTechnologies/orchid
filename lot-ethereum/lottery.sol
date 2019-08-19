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


pragma solidity ^0.5.7;

import "../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract OrchidLottery {

    ERC20 internal token_;

    constructor(address token) public {
        token_ = ERC20(token);
    }


    struct Pot {
        uint128 amount_;
        uint128 escrow_;
        uint256 unlock_;
    }

    mapping(address => Pot) internal pots_;

    event Update(address indexed signer, uint128 amount, uint128 escrow, uint256 unlock);

    function look(address signer) public view returns (uint128, uint128, uint256) {
        Pot storage pot = pots_[signer];
        return (pot.amount_, pot.escrow_, pot.unlock_);
    }


    // signer must be a simple account, to support signing tickets
    function fund(address signer, uint128 amount, uint128 total) public {
        require(total >= amount);
        Pot storage pot = pots_[signer];
        pot.amount_ += amount;
        pot.escrow_ += total - amount;
        emit Update(signer, pot.amount_, pot.escrow_, pot.unlock_);
        require(token_.transferFrom(msg.sender, address(this), total));
    }

    function move(uint128 amount) public {
        Pot storage pot = pots_[msg.sender];
        require(pot.amount_ >= amount);
        pot.amount_ -= amount;
        pot.escrow_ += amount;
        emit Update(msg.sender, pot.amount_, pot.escrow_, pot.unlock_);
    }


    struct Track {
        uint256 until_;
    }

    mapping(address => mapping(bytes32 => Track)) internal tracks_;

    function burn(Pot storage pot, uint128 amount) private returns (uint128) {
        if (pot.amount_ >= amount)
            return amount;
        else {
            pot.escrow_ = 0;
            return pot.amount_;
        }
    }

    function grab(uint256 secret, bytes32 hash, address payable target, uint256 nonce, uint256 until, uint256 ratio, uint128 amount, uint8 v, bytes32 r, bytes32 s, bytes32[] memory old) public {
        require(keccak256(abi.encodePacked(secret)) == hash);
        require(uint256(keccak256(abi.encodePacked(secret, nonce))) < ratio);
        require(until > block.timestamp);

        bytes32 ticket = keccak256(abi.encodePacked(hash, target, nonce, until, ratio, amount));

        require(tracks_[target][ticket].until_ == 0);
        tracks_[target][ticket].until_ = until;

        for (uint256 i = 0; i != old.length; ++i) {
            Track storage track = tracks_[target][old[i]];
            require(track.until_ <= block.timestamp);
            delete track.until_;
        }

        address signer = ecrecover(ticket, v, r, s);
        Pot storage pot = pots_[signer];
        amount = burn(pot, amount);
        pot.amount_ -= amount;
        emit Update(signer, pot.amount_, pot.escrow_, pot.unlock_);
        if (amount != 0)
            require(token_.transfer(target, amount));
    }

    function pull(address payable target, uint128 amount) public {
        Pot storage pot = pots_[msg.sender];
        amount = burn(pot, amount);
        pot.amount_ -= amount;
        emit Update(msg.sender, pot.amount_, pot.escrow_, pot.unlock_);
        require(token_.transfer(target, amount));
    }


    function warn() public {
        Pot storage pot = pots_[msg.sender];
        pot.unlock_ = block.timestamp + 1 days;
        emit Update(msg.sender, pot.amount_, pot.escrow_, pot.unlock_);
    }

    function lock() public {
        Pot storage pot = pots_[msg.sender];
        pot.unlock_ = 0;
        emit Update(msg.sender, pot.amount_, pot.escrow_, pot.unlock_);
    }

    function take(address payable target) public {
        Pot storage pot = pots_[msg.sender];
        require(pot.unlock_ != 0);
        require(pot.unlock_ <= block.timestamp);
        uint128 amount = pot.amount_ + pot.escrow_;
        delete pots_[msg.sender];
        emit Update(msg.sender, 0, 0, 0);
        require(token_.transfer(target, amount));
    }
}
