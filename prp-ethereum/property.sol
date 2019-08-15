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

interface IOrchidProperty {
}

contract OrchidProperty is IOrchidProperty {

    struct Location {
        uint256 time_;
        bytes data_;
    }

    mapping(address => Location) private locations_;

    function move(bytes memory data) public {
        Location storage location = locations_[msg.sender];
        location.time_ = block.timestamp;
        location.data_ = data;
    }

    function stop() public {
        delete locations_[msg.sender];
    }

    function look(address stakee) public view returns (uint256 time, bytes memory data) {
        Location storage location = locations_[stakee];
        return (location.time_, location.data_);
    }

}
