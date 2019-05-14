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

interface IOrchidDirectory {
    function have() external view returns (uint64 amount);
}

contract OrchidDirectory is IOrchidDirectory {

    ERC20 private orchid_;

    constructor(address orchid) public {
        orchid_ = ERC20(orchid);
    }



    struct Primary {
        address staker_;
        address stakee_;
    }

    function copy(Primary storage primary, address staker, address stakee) private {
        primary.staker_ = staker;
        primary.stakee_ = stakee;
    }

    function copy(Primary storage primary, Primary storage other) private {
        copy(primary, other.staker_, other.stakee_);
    }

    function kill(Primary storage primary) private {
        copy(primary, address(0), address(0));
    }

    function nope(Primary storage primary) private view returns (bool) {
        return primary.staker_ == address(0);
    }

    function name(address staker, address stakee) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(staker, stakee));
    }

    function name(Primary storage primary) private view returns (bytes32) {
        return name(primary.staker_, primary.stakee_);
    }



    struct Medallion {
        uint64 before_;
        uint64 after_;

        uint64 amount_;

        bytes32 parent_;
        Primary left_;
        Primary right_;
    }

    mapping(bytes32 => Medallion) private medallions_;

    Primary private root_;


    function have() public view returns (uint64 amount) {
        if (nope(root_))
            return 0;
        Medallion storage medallion = medallions_[name(root_)];
        return medallion.before_ + medallion.after_ + medallion.amount_;
    }

    function scan(uint128 percent) public view returns (address) {
        uint64 point = uint64(have() * uint256(percent) / 2**128);

        Primary storage primary = root_;
        for (;;) {
            require(!nope(primary));
            Medallion storage medallion = medallions_[name(primary)];

            if (point < medallion.before_) {
                primary = medallion.left_;
                continue;
            }

            point -= medallion.before_;

            if (point < medallion.amount_)
                return primary.stakee_;

            point -= medallion.amount_;

            primary = medallion.right_;
        }
    }


    function step(bytes32 key, Medallion storage medallion, uint64 amount, bytes32 root) private {
        while (medallion.parent_ != root) {
            bytes32 parent = medallion.parent_;
            medallion = medallions_[parent];
            if (name(medallion.left_) == key)
                medallion.before_ += amount;
            else
                medallion.after_ += amount;
            key = parent;
        }
    }

    function done(bytes32 key, Medallion storage medallion, uint64 amount) private {
        require(amount != 0);
        medallion.amount_ += amount;
        step(key, medallion, amount, bytes32(0));
        require(orchid_.transferFrom(msg.sender, address(this), amount));
    }

    function make(address stakee, uint64 amount) public {
        address staker = msg.sender;
        bytes32 key = name(staker, stakee);
        Medallion storage medallion = medallions_[key];
        require(medallion.amount_ == 0);

        bytes32 parent = bytes32(0);
        Primary storage primary = root_;

        while (!nope(primary)) {
            parent = name(primary);
            Medallion storage current = medallions_[parent];
            primary = current.before_ < current.after_ ? current.left_ : current.right_;
        }

        medallion.parent_ = parent;
        copy(primary, staker, stakee);

        done(key, medallion, amount);
    }

    function push(address stakee, uint64 amount) public {
        address staker = msg.sender;
        bytes32 key = name(staker, stakee);
        Medallion storage medallion = medallions_[key];
        require(medallion.amount_ != 0);

        done(key, medallion, amount);
    }



    struct Pending {
        uint256 time_;
        uint64 amount_;
    }

    mapping(address => mapping(uint => Pending)) private pendings_;

    function take(uint256 index, address payable target) public {
        Pending memory pending = pendings_[msg.sender][index];
        require(pending.amount_ != 0);
        require(pending.time_ <= block.timestamp);
        delete pendings_[msg.sender][index];
        require(orchid_.transfer(target, pending.amount_));
    }

    function pull(address stakee, uint64 amount, uint256 index) public {
        address staker = msg.sender;
        bytes32 key = name(staker, stakee);
        Medallion storage medallion = medallions_[key];

        require(amount != 0);
        require(medallion.amount_ >= amount);
        medallion.amount_ -= amount;

        step(key, medallion, -amount, bytes32(0));

        if (medallion.amount_ == 0) {
            if (medallion.parent_ == bytes32(0))
                delete root_;
            else {
                Medallion storage current = medallions_[medallion.parent_];
                Primary storage pivot = name(current.left_) == key ? current.left_ : current.right_;
                Primary storage child = medallion.before_ > medallion.after_ ? medallion.left_ : medallion.right_;

                if (nope(child))
                    kill(pivot);
                else {
                    Primary storage last = child;
                    for (;;) {
                        current = medallions_[name(last)];
                        Primary storage next = current.before_ > current.after_ ? current.left_ : current.right_;
                        if (nope(next)) {
                            if (current.parent_ != key)
                                medallions_[name(child)].parent_ = name(last);
                            (medallion.parent_, current.parent_) = (current.parent_, medallion.parent_);

                            current.before_ = medallion.before_;
                            current.after_ = medallion.after_;
                            current.left_ = medallion.left_;
                            current.right_ = medallion.right_;

                            copy(pivot, last);
                            copy(last, staker, stakee);
                            step(key, medallion, -current.amount_, current.parent_);
                            kill(last);
                            break;
                        }

                        last = next;
                    }
                }
            }

            delete medallions_[key];
        }

        Pending storage pending = pendings_[msg.sender][index];
        require(pending.amount_ == 0);
        pending.time_ = block.timestamp + 30 days;
        pending.amount_ = amount;
    }



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
