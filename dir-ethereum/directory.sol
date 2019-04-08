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

contract OrchidDirectory {
    ERC20 Orchid_ = ERC20(0x0);

    //event Support(address owner, uint256 capability);

    struct Medallion {
        uint256 network_;
        //mapping(uint256 => bytes) capabilities_;
    }

    mapping(address => Medallion) public medallions_;

    struct Weight {
        address owner_;
        uint staked_;
    }

    Weight[] weights_;

    function stake(address owner, uint staked, uint256 network) public returns (uint index) {
        require(staked >= 0);

        Medallion memory medallion;
        medallion.network_ = network;
        medallions_[owner] = medallion;

        Weight memory weight;
        weight.owner_ = owner;
        weight.staked_ = staked;

        index = weights_.push(weight) - 1;

        require(Orchid_.transferFrom(msg.sender, address(this), staked));
    }

    function take(uint index, address payable target, uint8 v, bytes32 r, bytes32 s) public {
        require(index < weights_.length);

        bytes32 hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(target))));
        address owner = ecrecover(hash, v, r, s);
        require(owner == weights_[index].owner_);

        uint256 staked = weights_[index].staked_;
        require(staked != 0);
        weights_[index].staked_ = 0;

        require(Orchid_.transfer(target, staked));
    }

    function random(uint percent) public view returns (uint256) {
        uint e = weights_.length;

        uint stop = 0;
        for (uint i = 0; i != e; ++i)
            stop += weights_[i].staked_;
        stop = stop * percent / 10**18;

        for (uint i = 0; i != e; ++i) {
            stop -= weights_[i].staked_;
            if (stop <= 0)
                return medallions_[weights_[i].owner_].network_;
        }
        return 0;
    }
}
