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
        uint128 winprob_;
        uint128 faceval_;
        uint128 expval_;
        uint128 lastWinner_;
    }
    mapping(address => Pot) internal pots_;

    mapping(address => int256) internal dbalances_;


    event Update(address indexed signer, uint128 amount, uint128 escrow, uint256 unlock);

    function balance(address signer) public view returns(uint128, uint128) {
        Pot storage pot = pots_[signer];
        return (pot.amount_, pot.escrow_);
    }

    // signer must be a simple account, to support signing tickets
    function fund(address signer, uint128 amount, uint128 total, uint128 winprob, uint128 faceval, uint128 expval) public {
        require(total >= amount);
        Pot storage pot = pots_[signer];
        pot.amount_ += amount;
        pot.escrow_ += total - amount;
        pot.lastWinner_ = 0;
        pot.winprob_ = winprob;
        pot.faceval_ = faceval;
        pot.expval_  = expval;
        emit Update(signer, pot.amount_, pot.escrow_, pot.unlock_);
        require(token_.transferFrom(msg.sender, address(this), total));
    }


    function grab(uint256 secret, bytes32 hash, address payable target, uint256 nonce, uint256 until, uint8 v, bytes32 r, bytes32 s, uint128 lastWinner, uint128 newWinner) public {

        require(keccak256(abi.encodePacked(secret)) == hash);
        require(until > block.timestamp);

        bytes32 ticket  = keccak256(abi.encodePacked(hash, target, nonce, until, lastWinner));

        address signer  = ecrecover(ticket, v, r, s);
        Pot storage pot = pots_[signer];

        require(uint256(keccak256(abi.encodePacked(secret, nonce))) < pot.winprob_);
        
        uint256 faceval  = pot.faceval_;
        uint256 toteval  = (newWinner - lastWinner) * pot.expval_; 

        require(newWinner > pot.lastWinner_); // to prevent replay       
		//require(lastWinner == pot.lastWinner_);
		//if (lastWinner != pot.lastWinner_) { pot.amount_ = 0; }

        if (pot.amount_ < toteval) {
            faceval 	= toteval = pot.amount_;
            pot.escrow_ = 0;
        }
        
        pot.amount_    -= toteval;
        pot.lastWinner_ = newWinner;

		int256 dbal  = dbalances_[target] + toteval;
		faceval      = min(faceval,  dbal);
		dbalances_[target] = dbal - faceval;

        emit Update(signer, pot.amount_, pot.escrow_, pot.unlock_);

        if (faceval != 0)
            require(token_.transfer(target, faceval));
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
        uint128 amount = pot.amount_ + pot.escrow_;
        delete pots_[msg.sender];
        emit Update(msg.sender, 0, 0, 0);
        require(token_.transfer(target, amount));
    }
}
