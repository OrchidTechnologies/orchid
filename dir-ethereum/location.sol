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


pragma solidity 0.5.13;

contract OrchidLocation {
    struct Location {
        uint256 set_;
        bytes url_;
        bytes tls_;
        bytes gpg_;
    }

    mapping (address => Location) private locations_;

    event Update(address indexed provider);

    function poke() external {
        Location storage location = locations_[msg.sender];
        location.set_ = block.timestamp;
        emit Update(msg.sender);
    }

    function move(bytes calldata url, bytes calldata tls, bytes calldata gpg) external {
        Location storage location = locations_[msg.sender];
        location.set_ = block.timestamp;
        location.url_ = url;
        location.tls_ = tls;
        location.gpg_ = gpg;
        emit Update(msg.sender);
    }

    function look(address target) external view returns (uint256, bytes memory, bytes memory, bytes memory) {
        Location storage location = locations_[target];
        return (location.set_, location.url_, location.tls_, location.gpg_);
    }
}
