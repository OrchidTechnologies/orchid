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

contract Resolver {
    function setName(bytes32 node, string memory name) public;
}

contract ReverseRegistrar {
    function setName(string memory name) public returns (bytes32 node);
    function claim(address owner) public returns (bytes32 node);
    function claimWithResolver(address owner, address resolver) public returns (bytes32 node);
    function node(address addr) public pure returns (bytes32);
}

contract OrchidCurator {
    function good(address, bytes calldata) external view returns (bool);
}

contract OrchidList is OrchidCurator {
    address private owner_;

    struct Entry {
        address prev_;
        address next_;
        bytes data_;
    }

    mapping (address => Entry) private entries_;

    constructor() public {
        owner_ = msg.sender;
        Entry storage root = entries_[address(this)];
        root.prev_ = address(this);
        root.next_ = address(this);
    }

    function hand(address owner) external {
        require(msg.sender == owner_);
        owner_ = owner;
    }

    function call(address target, bytes calldata data) payable external returns (bool, bytes memory) {
        require(msg.sender == owner_);
        return target.call.value(msg.value)(data);
    }

    function list(address provider, bytes calldata data) external {
        require(msg.sender == owner_);

        require(provider != address(this));
        Entry storage here = entries_[provider];

        require(data.length != 0);
        bool done = here.data_.length != 0;
        here.data_ = data;
        if (done) return;

        Entry storage prev = entries_[address(this)];
        Entry storage next = entries_[prev.next_];

        here.prev_ = address(this);
        here.next_ = prev.next_;

        prev.next_ = provider;
        next.prev_ = provider;
    }

    function kill(address provider) external {
        require(msg.sender == owner_);

        Entry storage here = entries_[provider];
        if (here.data_.length == 0)
            return;

        Entry storage prev = entries_[here.prev_];
        Entry storage next = entries_[here.next_];

        prev.next_ = here.next_;
        next.prev_ = here.prev_;

        delete entries_[provider];
    }

    function look(address provider) external view returns (address, address, bytes memory) {
        Entry storage entry = entries_[provider];
        return (entry.prev_, entry.next_, entry.data_);
    }

    function good(address provider, bytes calldata) external view returns (bool) {
        require(entries_[provider].data_.length != 0);
        return true;
    }
}

contract OrchidSelect is OrchidCurator {
    function good(address provider, bytes calldata argument) external view returns (bool) {
        require(argument.length == 20);
        address allowed;
        bytes memory copy = argument;
        assembly { allowed := mload(add(copy, 20)) }
        require(provider == allowed);
        return true;
    }
}

contract OrchidUntrusted is OrchidCurator {
    function good(address, bytes calldata) external view returns (bool) {
        return true;
    }
}
