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
    function have() external view returns (uint128 amount);
}

contract OrchidDirectory is IOrchidDirectory {

    ERC20 internal token_;

    constructor(address token) public {
        token_ = ERC20(token);
    }



    struct Primary {
        bytes32 value_;
    }

    function name(address staker, address stakee) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(staker, stakee));
    }

    function name(Primary storage primary) private view returns (bytes32) {
        return primary.value_;
    }

    function copy(Primary storage primary, address staker, address stakee) private {
        primary.value_ = name(staker, stakee);
    }

    function copy(Primary storage primary, Primary storage other) private {
        primary.value_ = other.value_;
    }

    function kill(Primary storage primary) private {
        primary.value_ = bytes32(0);
    }

    function nope(Primary storage primary) private view returns (bool) {
        return primary.value_ == bytes32(0);
    }



    struct Medallion {
        uint128 before_;
        uint128 after_;

        uint128 amount_;
        uint128 delay_;

        address stakee_;

        bytes32 parent_;
        Primary left_;
        Primary right_;
    }

    mapping(bytes32 => Medallion) internal medallions_;

    Primary private root_;


    function have() public view returns (uint128 amount) {
        if (nope(root_))
            return 0;
        Medallion storage medallion = medallions_[name(root_)];
        return medallion.before_ + medallion.after_ + medallion.amount_;
    }

    function scan(uint128 percent) public view returns (address) {
        require(!nope(root_));

        uint128 point = uint128(have() * uint256(percent) / 2**128);

        Primary storage primary = root_;
        for (;;) {
            Medallion storage medallion = medallions_[name(primary)];

            if (point < medallion.before_) {
                primary = medallion.left_;
                continue;
            }

            point -= medallion.before_;

            if (point < medallion.amount_)
                return medallion.stakee_;

            point -= medallion.amount_;

            primary = medallion.right_;
        }
    }


    function step(bytes32 key, Medallion storage medallion, uint128 amount, bytes32 root) private {
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

    function more(address stakee, uint128 amount, uint128 delay) private {
        address staker = msg.sender;
        bytes32 key = name(staker, stakee);
        Medallion storage medallion = medallions_[key];

        require(delay >= medallion.delay_);
        medallion.delay_ = delay;

        if (medallion.amount_ == 0) {
            require(amount != 0);

            bytes32 parent = bytes32(0);
            Primary storage primary = root_;

            while (!nope(primary)) {
                parent = name(primary);
                Medallion storage current = medallions_[parent];
                primary = current.before_ < current.after_ ? current.left_ : current.right_;
            }

            medallion.parent_ = parent;
            copy(primary, staker, stakee);

            medallion.stakee_ = stakee;
        }

        medallion.amount_ += amount;
        step(key, medallion, amount, bytes32(0));
    }

    function push(address stakee, uint128 amount, uint128 delay) public {
        more(stakee, amount, delay);
        require(token_.transferFrom(msg.sender, address(this), amount));
    }


    struct Pending {
        uint256 time_;
        address stakee_;
        uint128 amount_;
    }

    mapping(address => mapping(uint256 => Pending)) private pendings_;

    function take(uint256 index, address payable target) public {
        Pending memory pending = pendings_[msg.sender][index];
        require(pending.time_ <= block.timestamp);
        delete pendings_[msg.sender][index];
        require(token_.transfer(target, pending.amount_));
    }

    function stop(uint256 index, uint128 delay) public {
        Pending memory pending = pendings_[msg.sender][index];
        require(pending.time_ <= block.timestamp + delay);
        delete pendings_[msg.sender][index];
        more(pending.stakee_, pending.amount_, delay);
    }

    function pull(address stakee, uint128 amount, uint256 index) public {
        address staker = msg.sender;
        bytes32 key = name(staker, stakee);
        Medallion storage medallion = medallions_[key];
        uint128 delay = medallion.delay_;

        require(medallion.amount_ != 0);
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
                        if (nope(next))
                            break;
                        last = next;
                    }

                    bytes32 direct = current.parent_;
                    copy(pivot, last);
                    current.parent_ = medallion.parent_;

                    if (direct == key) {
                        Primary storage other = medallion.before_ > medallion.after_ ? medallion.right_ : medallion.left_;
                        if (!nope(other))
                            medallions_[name(other)].parent_ = name(last);

                        if (name(medallion.left_) == key) {
                            current.right_ = medallion.right_;
                            current.after_ = medallion.after_;
                        } else {
                            current.left_ = medallion.left_;
                            current.before_ = medallion.before_;
                        }
                    } else {
                        if (!nope(medallion.left_))
                            medallions_[name(medallion.left_)].parent_ = name(last);
                        if (!nope(medallion.right_))
                            medallions_[name(medallion.right_)].parent_ = name(last);

                        current.right_ = medallion.right_;
                        current.after_ = medallion.after_;

                        current.left_ = medallion.left_;
                        current.before_ = medallion.before_;

                        medallion.parent_ = direct;
                        copy(last, staker, stakee);
                        step(key, medallion, -current.amount_, current.parent_);
                        kill(last);
                    }
                }
            }

            delete medallions_[key];
        }

        Pending storage pending = pendings_[msg.sender][index];
        pending.time_ = block.timestamp + delay;
        pending.stakee_ = stakee;
        pending.amount_ += amount;
    }

}
