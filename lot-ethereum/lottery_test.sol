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


pragma solidity 0.5.12;

import "lottery.sol";


contract TestOrchidLottery is OrchidLottery
{

    constructor(address token) public OrchidLottery(token) {}

// ============== test functions ======================================================================

    function test_ecrecover(bytes32 hdata, uint8 v, bytes32 r, bytes32 s, address signer)   public pure returns (address)
    { 
        address signer2 = ecrecover(hdata, v, r, s);
        require(signer2 == signer); // this is currently failing, not sure why yet
        return signer2; 
    }

    //function grab(uint256 secret, bytes32 hash, address payable target, uint256 nonce, uint256 until, uint256 ratio, uint128 amount, uint8 v, bytes32 r, bytes32 s, bytes32[] memory old) public 
    function grab2(uint256 secret, bytes32 hash, address payable target, uint256 nonce, uint256 until, uint256 ratio, uint128 amount, uint8 v, bytes32 r, bytes32 s, 
    address sender, bytes32 thash) public 
    {
        require(keccak256(abi.encodePacked(secret)) == hash);
        require(uint256(keccak256(abi.encodePacked(secret, nonce))) < ratio);
        require(until > block.timestamp);

        bytes32 ticket = keccak256(abi.encodePacked(hash, target, nonce, until, ratio, amount));
        require(ticket == thash);

        address signer = ecrecover(ticket, v, r, s);
        require(sender == signer);
        
        Pot storage pot = pots_[signer];

        if (pot.amount_ < amount) {
            amount = pot.amount_;
            pot.escrow_ = 0;
        }

        pot.amount_ -= amount;
        emit Update(signer, pot.amount_, pot.escrow_, pot.unlock_);
        if (amount != 0)
            require(token_.transfer(target, amount));
            
        /*
        */
    }



    function test_func(uint256 x)   public pure returns (uint256)    { return x; }

    function get_address(uint256)   public view returns (address)    { return address(this); }

    function get_token(uint256)     public view returns (address)    { return address(token_); }
    function set_token(address x)   public                           { token_ = IERC20(x); }

    function get_amount(address x)  public view returns (uint128)    { return pots_[x].amount_; }
    function get_escrow(address x)  public view returns (uint128)    { return pots_[x].escrow_; }
    function get_unlock(address x)  public view returns (uint256)    { return pots_[x].unlock_; }

    function hash_test_(address payable target) public pure returns (bytes32)
    {
        bytes32 ticket = keccak256(abi.encodePacked(target)); return ticket;
    }

    function hash_test(bytes32 hash, address payable target, uint256 nonce, uint256 until, uint256 ratio, uint64 amount) public pure returns (bytes32)
    {
        bytes32 ticket = keccak256(abi.encodePacked(hash, target, nonce, until, ratio, amount)); return ticket;
    }



}
