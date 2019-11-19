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

import "../openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract OrchidDirectory {

    IERC20 internal token_;

    constructor(address token) public {
        token_ = IERC20(token);
    }


    struct Stakee {
        uint256 amount_;
    }

    mapping(address => Stakee) internal stakees_;

    function heft(address stakee) external view returns (uint256) {
        return stakees_[stakee].amount_;
    }


    struct Primary {
        bytes32 value_;
        uint256 below_;
    }

    function name(address staker, address stakee) public pure returns (bytes32) {
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


    struct Stake {
        uint256 amount_;
        uint128 delay_;

        address stakee_;

        bytes32 parent_;
        Primary left_;
        Primary right_;
    }

    mapping(bytes32 => Stake) internal stakes_;

    Primary private root_;


    function have() public view returns (uint256) {
        if (nope(root_))
            return 0;
        Stake storage stake = stakes_[name(root_)];
        return stake.left_.below_ + stake.right_.below_ + stake.amount_;
    }

    function scan(uint256 point) public view returns (bytes32, address, uint128) {
        require(!nope(root_));

        Primary storage primary = root_;
        for (;;) {
            bytes32 key = name(primary);
            Stake storage stake = stakes_[key];

            if (point < stake.left_.below_) {
                primary = stake.left_;
                continue;
            }

            point -= stake.left_.below_;

            if (point < stake.amount_)
                return (key, stake.stakee_, stake.delay_);

            point -= stake.amount_;

            primary = stake.right_;
        }
    }

    // provide a single-call variant of scan() that works for initial OXT clients
    function scan(uint128 percent) external view returns (bytes32, address, uint128) {
        // for OXT, have() will be less than a uint128, so this math cannot overflow
        return scan(have() * percent >> 128);
    }


    function side(Stake storage stake, bool less) private view returns (Primary storage) {
        return (stake.left_.below_ < stake.right_.below_) == less ? stake.left_ : stake.right_;
    }

    function side(Stake storage stake, bytes32 key) private view returns (Primary storage) {
        return name(stake.left_) == key ? stake.left_ : stake.right_;
    }

    function turn(bytes32 key, Stake storage stake) private view returns (Primary storage) {
        if (stake.parent_ == bytes32(0))
            return root_;
        return side(stakes_[stake.parent_], key);
    }


    function step(bytes32 key, Stake storage stake, uint256 amount, bytes32 root) private {
        while (stake.parent_ != root) {
            bytes32 parent = stake.parent_;
            stake = stakes_[parent];
            side(stake, key).below_ += amount;
            key = parent;
        }
    }

    event Update(address indexed staker, address stakee, uint256 amount);
    event Update(address indexed stakee, uint256 amount);

    function lift(bytes32 key, Stake storage stake, uint256 amount, address staker, address stakee) private {
        uint256 local = stake.amount_;
        local += amount;
        stake.amount_ = local;
        emit Update(staker, stakee, local);

        uint256 global = stakees_[stakee].amount_;
        global += amount;
        stakees_[stakee].amount_ = global;
        emit Update(stakee, global);

        step(key, stake, amount, bytes32(0));
    }


    function more(address stakee, uint256 amount, uint128 delay) private {
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
                primary = current.left_.below_ < current.right_.below_ ? current.left_ : current.right_;
            }

            stake.parent_ = parent;
            copy(primary, staker, stakee);

            stake.stakee_ = stakee;
        }

        lift(key, stake, amount, staker, stakee);
    }

    function push(address stakee, uint256 amount, uint128 delay) external {
        more(stakee, amount, delay);
        require(token_.transferFrom(msg.sender, address(this), amount));
    }

    function wait(address stakee, uint128 delay) external {
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
        uint256 amount_;
    }

    mapping(address => mapping(uint256 => Pending)) private pendings_;

    function take(uint256 index, address payable target) external {
        Pending memory pending = pendings_[msg.sender][index];
        require(pending.expire_ <= block.timestamp);
        delete pendings_[msg.sender][index];
        require(token_.transfer(target, pending.amount_));
    }

    function stop(uint256 index, uint128 delay) external {
        Pending memory pending = pendings_[msg.sender][index];
        require(pending.expire_ <= block.timestamp + delay);
        delete pendings_[msg.sender][index];
        more(pending.stakee_, pending.amount_, delay);
    }


    function move(Primary storage stake, bytes32 location, Primary storage current) private {
        if (nope(stake))
            return;
        stakes_[name(stake)].parent_ = location;
        copy(current, stake);
        current.below_ = stake.below_;
    }

    function fixr(Stake storage stake, bytes32 location, Stake storage current) private {
        move(stake.right_, location, current.right_);
    }

    function fixl(Stake storage stake, bytes32 location, Stake storage current) private {
        move(stake.left_, location, current.left_);
    }

    function pull(address stakee, uint256 amount, uint256 index) external {
        address staker = msg.sender;
        bytes32 key = name(staker, stakee);
        Stake storage stake = stakes_[key];
        uint128 delay = stake.delay_;

        require(stake.amount_ != 0);
        require(stake.amount_ >= amount);

        lift(key, stake, -amount, staker, stakee);

        if (stake.amount_ == 0) {
            Primary storage pivot = turn(key, stake);
            Primary storage child = side(stake, false);

            if (nope(child))
                kill(pivot);
            else {
                Primary storage last = child;
                bytes32 location = name(last);
                Stake storage current = stakes_[location];
                for (;;) {
                    Primary storage next = side(current, false);
                    if (nope(next))
                        break;
                    last = next;
                    location = name(last);
                    current = stakes_[location];
                }

                bytes32 direct = current.parent_;
                copy(pivot, last);
                current.parent_ = stake.parent_;

                if (direct != key) {
                    fixr(stake, location, current);
                    fixl(stake, location, current);

                    stake.parent_ = direct;
                    copy(last, staker, stakee);
                    step(key, stake, -current.amount_, current.parent_);
                    kill(last);
                } else if (name(stake.left_) == location) {
                    fixr(stake, location, current);
                } else {
                    fixl(stake, location, current);
                }
            }

            delete stakes_[key];
        }

        Pending storage pending = pendings_[msg.sender][index];
        require(pending.amount_ == 0);
        pending.expire_ = block.timestamp + delay;
        pending.stakee_ = stakee;
        pending.amount_ = amount;
    }

}
