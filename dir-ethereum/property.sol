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

contract OrchidProperty {
    mapping(address => mapping (address => mapping (bytes => bytes))) private data_;

    function get(address target, address owner, bytes memory key) public view returns (bytes memory) {
        return data_[target][owner][key];
    }

    function get32(address target, address owner, bytes memory key) public view returns (bytes32) {
        bytes memory value = get(target, owner, key);
        require(value.length == 32);
        bytes32 value32;
        assembly { value32 := mload(add(0x20, value)) }
        return value32;
    }

    event Update(address indexed target, address owner, bytes key, bytes value);
    event Update(address target, bytes32 indexed combined, bytes value);
    event Update(bytes32 indexed combined, bytes value);

    function set(address target, bytes memory key, bytes memory value) public {
        address owner = msg.sender;
        data_[target][owner][key] = value;

        emit Update(target, owner, key, value);
        emit Update(target, keccak256(abi.encodePacked(owner, key)), value);
        emit Update(keccak256(abi.encodePacked(target, owner, key)), value);
    }

    function set32(address target, bytes memory key, bytes32 value) public {
        set(target, key, abi.encodePacked(value));
    }
}

contract OrchidLocation {
    OrchidProperty properties_;

    constructor(address properties) public {
        properties_ = OrchidProperty(properties);
    }

    function move(string memory url, string memory tls) public {
        address target = msg.sender;
        properties_.set32(target, "set", bytes32(block.timestamp));
        properties_.set(target, "url", bytes(url));
        properties_.set(target, "tls", bytes(tls));
    }

    function stop() public {
        address target = msg.sender;
        properties_.set32(target, "set", bytes32(block.timestamp));
        properties_.set(target, "url", "");
        properties_.set(target, "tls", "");
    }

    function look(address target) public view returns (uint256, string memory, string memory) {
        return (
            uint256(properties_.get32(target, address(this), "set")),
            string(properties_.get(target, address(this), "url")),
            string(properties_.get(target, address(this), "tls"))
        );
    }
}
