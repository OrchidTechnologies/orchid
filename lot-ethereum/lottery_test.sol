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

import "lottery.sol";


//contract TestOrchidLottery is IOrchidLottery
contract TestOrchidLottery // couldn't get derivation to compile to valid binary
{
    ERC20 private orchid_;

    constructor(address orchid) public {
        orchid_ = ERC20(orchid);
    }


    struct Pot {
        uint64 amount_;
        uint64 escrow_;
        uint256 unlock_;
    }

    mapping(address => Pot) pots_;

    event Update(address indexed signer, uint64 amount, uint64 escrow, uint256 unlock);

    // signer must be a simple account, to support signing tickets
    function fund(address signer, uint64 amount, uint64 total) public {
        require(total >= amount);
        Pot storage pot = pots_[signer];
        pot.amount_ += amount;
        pot.escrow_ += total - amount;
        emit Update(signer, pot.amount_, pot.escrow_, pot.unlock_);
        require(orchid_.transferFrom(msg.sender, address(this), total));
    }


    struct Track {
        uint256 until_;
    }

    mapping(address => mapping(bytes32 => Track)) tracks_;

    //function grab(uint256 secret, bytes32 hash, address payable target, uint256 nonce, uint256 until, uint256 ratio, uint64 amount, uint8 v, bytes32 r, bytes32 s, bytes32[] memory old) public 
    function grab(uint256 secret, bytes32 hash, address payable target, uint256 nonce, uint256 until, uint256 ratio, uint64 amount, uint8 v, bytes32 r, bytes32 s) public 
    {
        require(keccak256(abi.encodePacked(secret)) == hash);
        require(uint256(keccak256(abi.encodePacked(secret, nonce))) < ratio);
        require(until > block.timestamp);

        bytes32 ticket = keccak256(abi.encodePacked(hash, target, nonce, until, ratio, amount));

        /*
        require(tracks_[target][ticket].until_ == 0);
        tracks_[target][ticket].until_ = until;

        for (uint256 i = 0; i != old.length; ++i) {
            Track storage track = tracks_[target][old[i]];
            require(track.until_ <= block.timestamp);
            delete track.until_;
        }
        */

        address signer = ecrecover(ticket, v, r, s);
        Pot storage pot = pots_[signer];

        if (pot.amount_ < amount) {
            amount = pot.amount_;
            pot.escrow_ = 0;
        }

        pot.amount_ -= amount;
        emit Update(signer, pot.amount_, pot.escrow_, pot.unlock_);
        if (amount != 0)
            require(orchid_.transfer(target, amount));
    }


    function warn() public {
        Pot storage pot = pots_[msg.sender];
        pot.unlock_ = block.timestamp + 1 days;
        emit Update(msg.sender, pot.amount_, pot.escrow_, pot.unlock_);
    }

    function take(address payable target) public {
        Pot storage pot = pots_[msg.sender];
        require(pot.unlock_ != 0);
        require(pot.unlock_ <= block.timestamp);
        uint64 amount = pot.amount_ + pot.escrow_;
        delete pots_[msg.sender];
        emit Update(msg.sender, 0, 0, 0);
        require(orchid_.transfer(target, amount));
    }


// ============== test functions ======================================================================

    function test_func(uint256 x)   public view returns (uint256)    { return x; }

    function get_address(uint256)   public view returns (address)    { return address(this); }

    function get_orchid(uint256)    public view returns (address)    { return address(orchid_); }
    function set_orchid(address x)  public                           { orchid_ = ERC20(x); }

    function get_amount(address x)  public view returns (uint64)     { return pots_[x].amount_; }
    function get_escrow(address x)  public view returns (uint64)     { return pots_[x].escrow_; }
    function get_unlock(address x)  public view returns (uint256)    { return pots_[x].unlock_; }

    function hash_test_(address payable target) public view returns (bytes32)
    {
        bytes32 ticket = keccak256(abi.encodePacked(target)); return ticket;
    }

    function hash_test(bytes32 hash, address payable target, uint256 nonce, uint256 until, uint256 ratio, uint64 amount) public view returns (bytes32)
    {
        bytes32 ticket = keccak256(abi.encodePacked(hash, target, nonce, until, ratio, amount)); return ticket;
    }



}
