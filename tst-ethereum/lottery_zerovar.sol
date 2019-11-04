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
        uint128 paydate_;
        address claimer_;
    }
    mapping(address => Pot) internal pots_;


    event Update(address indexed signer, uint128 amount, uint128 escrow, uint256 unlock);

    function balance(address signer) public view returns(uint128, uint128) {
        Pot storage pot = pots_[signer];
        return (pot.amount_, pot.escrow_);
    }

    // signer must be a simple account, to support signing tickets
    function fund(address signer, uint128 amount, uint128 total, uint128 paydate) public {
        require(total >= amount);
        Pot storage pot = pots_[signer];
        if (pot.amount_ > 0) { // can't change date or claimer
	        pot.paydate_ = paydate;
	        pot.claimer_ = 0;
	    }
        pot.amount_ += amount;
        pot.escrow_ += total - amount;
        emit Update(signer, pot.amount_, pot.escrow_, pot.unlock_);
        require(token_.transferFrom(msg.sender, address(this), total));
    }


    function claim(
    	address payable target, uint128 paydate, uint128 srange, uint128 erange,
    	uint8 v, bytes32 r, bytes32 s) public 
    {
        require(block.number > paydate);
        require(block.numer < paydate + 256); // EVM limitation

        bytes32 ticket  = keccak256(abi.encodePacked(target, paydate, srange, erange));
        address signer  = ecrecover(ticket, v, r, s);
        
        Pot storage pot = pots_[signer];
        require(pot.paydate_ == paydate); // consistency check

	    uint128 bhash   = blockhash(paydate);
	    require(bhash != 0); // safety check

		uint256 rval    = keccak256( abi.encodePacked(signer, bhash) );
        require((rval >= srange) && (rval < erange));  // winning condition
        
        if (pot.claimer_ != 0) { // more than one claimer, double-spend, burn everything
        	pot.amount_ = pot.escrow_ = 0;
        }
        else {
        	pot.claimer_ = target; // otherwise we can claim it
        }
    }
    
    
    function redeem(address source, address payable target)
    {
        Pot storage pot = pots_[source];

        require((pot.claimer_ == target) || (source == msg.sender));
        require(block.number > pot.paydate_ + 5760); // +1 day claim dispute period

		uint128 amount = 0;

		if (pot.claimer_ == target) { // only winner gets the pot
			amount += pot.amount_;
        	pot.amount_ = 0;
		}

        if (source == msg.sender) { // only owner gets the escrow
        	amount += pot.escrow_;
        	pot.escrow_ = 0;
        }

        if ((pot.amount_ == 0) && (pot.escrow_)) {
        	delete pots_[msg.sender];
        }

        emit Update(signer, pot.amount_, pot.escrow_, pot.unlock_);

        if (amount != 0)
            require(token_.transfer(target, amount));
    }


}
