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


    struct Stakee {
        uint128 amount_;
    }

    mapping(address => Stakee) internal stakees_;

    function heft(address stakee) public view returns (uint128 amount) {
        return stakees_[stakee].amount_;
    }


    struct Stake {
        uint128 before_;
        uint128 after_;

        uint128 amount_;
        uint128 delay_;

        address stakee_;

        bytes32 parent_;
        Primary left_;
        Primary right_;
    }

    mapping(bytes32 => Stake) internal stakes_;

    Primary private root_;


    function have() public view returns (uint128 amount) {
        if (nope(root_))
            return 0;
        Stake storage stake = stakes_[name(root_)];
        return stake.before_ + stake.after_ + stake.amount_;
    }

    function scan(uint128 percent) public view returns (address) {
        require(!nope(root_));

        uint128 point = uint128(have() * uint256(percent) / 2**128);

        Primary storage primary = root_;
        for (;;) {
            Stake storage stake = stakes_[name(primary)];

            if (point < stake.before_) {
                primary = stake.left_;
                continue;
            }

            point -= stake.before_;

            if (point < stake.amount_)
                return stake.stakee_;

            point -= stake.amount_;

            primary = stake.right_;
        }
    }


    function step(bytes32 key, Stake storage stake, uint128 amount, bytes32 root) private {
        while (stake.parent_ != root) {
            bytes32 parent = stake.parent_;
            stake = stakes_[parent];
            if (name(stake.left_) == key)
                stake.before_ += amount;
            else
                stake.after_ += amount;
            key = parent;
        }
    }

    function more(address stakee, uint128 amount, uint128 delay) private {
        address staker = msg.sender;
        bytes32 key = name(staker, stakee);
        Stake storage stake = stakes_[key];

        require(delay >= stake.delay_);
        stake.delay_ = delay;

        if (stake.amount_ == 0) {
            require(amount != 0);

            bytes32 parent = bytes32(0);
            Primary storage primary = root_;

            while (!nope(primary)) {
                parent = name(primary);
                Stake storage current = stakes_[parent];
                primary = current.before_ < current.after_ ? current.left_ : current.right_;
            }

            stake.parent_ = parent;
            copy(primary, staker, stakee);

            stake.stakee_ = stakee;
        }

        stake.amount_ += amount;
        stakees_[stakee].amount_ += amount;
        step(key, stake, amount, bytes32(0));
    }

    function push(address stakee, uint128 amount, uint128 delay) public {
        more(stakee, amount, delay);
        require(token_.transferFrom(msg.sender, address(this), amount));
    }

    function wait(address stakee, uint128 delay) public {
        address staker = msg.sender;
        bytes32 key = name(staker, stakee);
        Stake storage stake = stakes_[key];
        require(stake.amount_ != 0);

        require(delay >= stake.delay_);
        stake.delay_ = delay;
    }


    struct Pending {
        uint256 expire_;
        address stakee_;
        uint128 amount_;
    }

    mapping(address => mapping(uint256 => Pending)) private pendings_;

    function take(uint256 index, address payable target) public {
        Pending memory pending = pendings_[msg.sender][index];
        require(pending.expire_ <= block.timestamp);
        delete pendings_[msg.sender][index];
        require(token_.transfer(target, pending.amount_));
    }

    function stop(uint256 index, uint128 delay) public {
        Pending memory pending = pendings_[msg.sender][index];
        require(pending.expire_ <= block.timestamp + delay);
        delete pendings_[msg.sender][index];
        more(pending.stakee_, pending.amount_, delay);
    }

    function pull(address stakee, uint128 amount, uint256 index) public {
        address staker = msg.sender;
        bytes32 key = name(staker, stakee);
        Stake storage stake = stakes_[key];
        uint128 delay = stake.delay_;

        require(stake.amount_ != 0);
        require(stake.amount_ >= amount);

        stake.amount_ -= amount;
        stakees_[stakee].amount_ -= amount;
        step(key, stake, -amount, bytes32(0));

        if (stake.amount_ == 0) {
            if (stake.parent_ == bytes32(0))
                delete root_;
            else {
                Stake storage current = stakes_[stake.parent_];
                Primary storage pivot = name(current.left_) == key ? current.left_ : current.right_;
                Primary storage child = stake.before_ > stake.after_ ? stake.left_ : stake.right_;

                if (nope(child))
                    kill(pivot);
                else {
                    Primary storage last = child;
                    for (;;) {
                        current = stakes_[name(last)];
                        Primary storage next = current.before_ > current.after_ ? current.left_ : current.right_;
                        if (nope(next))
                            break;
                        last = next;
                    }

                    bytes32 direct = current.parent_;
                    copy(pivot, last);
                    current.parent_ = stake.parent_;

                    if (direct == key) {
                        Primary storage other = stake.before_ > stake.after_ ? stake.right_ : stake.left_;
                        if (!nope(other))
                            stakes_[name(other)].parent_ = name(last);

                        if (name(stake.left_) == key) {
                            current.right_ = stake.right_;
                            current.after_ = stake.after_;
                        } else {
                            current.left_ = stake.left_;
                            current.before_ = stake.before_;
                        }
                    } else {
                        if (!nope(stake.left_))
                            stakes_[name(stake.left_)].parent_ = name(last);
                        if (!nope(stake.right_))
                            stakes_[name(stake.right_)].parent_ = name(last);

                        current.right_ = stake.right_;
                        current.after_ = stake.after_;

                        current.left_ = stake.left_;
                        current.before_ = stake.before_;

                        stake.parent_ = direct;
                        copy(last, staker, stakee);
                        step(key, stake, -current.amount_, current.parent_);
                        kill(last);
                    }
                }
            }

            delete stakes_[key];
        }

        Pending storage pending = pendings_[msg.sender][index];
        pending.expire_ = block.timestamp + delay;
        pending.stakee_ = stakee;
        pending.amount_ += amount;
    }

}
