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

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract OrchidDirectory {

    IERC20 internal token_;

    constructor(IERC20 token) public {
        token_ = token;
    }

    function what() external view returns (IERC20) {
        return token_;
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
        uint256 before_;
        uint256 after_;

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
        return stake.before_ + stake.after_ + stake.amount_;
    }

    function seek(uint256 point) public view returns (address, uint128) {
        require(!nope(root_));

        Primary storage primary = root_;
        for (;;) {
            bytes32 key = name(primary);
            Stake storage stake = stakes_[key];

            if (point < stake.before_) {
                primary = stake.left_;
                continue;
            }

            point -= stake.before_;

            if (point < stake.amount_)
                return (stake.stakee_, stake.delay_);

            point -= stake.amount_;

            primary = stake.right_;
        }
    }

    function pick(uint128 percent) external view returns (address, uint128) {
        // for OXT, have() will be less than a uint128, so this math cannot overflow
        return seek(have() * percent >> 128);
    }


    function turn(bytes32 key, Stake storage stake) private view returns (Primary storage) {
        if (stake.parent_ == bytes32(0))
            return root_;
        Stake storage parent = stakes_[stake.parent_];
        return name(parent.left_) == key ? parent.left_ : parent.right_;
    }


    function step(bytes32 key, Stake storage stake, uint256 amount, bytes32 root) private {
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

    event Update(address indexed stakee, address indexed staker, uint256 local, uint256 global);

    function lift(bytes32 key, Stake storage stake, uint256 amount, address staker, address stakee) private {
        uint256 local = stake.amount_;
        local += amount;
        stake.amount_ = local;

        uint256 global = stakees_[stakee].amount_;
        global += amount;
        stakees_[stakee].amount_ = global;

        emit Update(stakee, staker, local, global);
        step(key, stake, amount, bytes32(0));
    }


    event Delay(address indexed stakee, address indexed staker, uint128 delay);

    function wait(Stake storage stake, uint128 delay, address staker, address stakee) private {
        if (stake.delay_ != delay) {
            require(stake.delay_ < delay);
            stake.delay_ = delay;
            emit Delay(stakee, staker, delay);
        }
    }

    function more(address stakee, uint256 amount, uint128 delay) private {
        address staker = msg.sender;
        bytes32 key = name(staker, stakee);
        Stake storage stake = stakes_[key];

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

        wait(stake, delay, staker, stakee);
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
        wait(stake, delay, staker, stakee);
    }


    struct Pending {
        uint256 expire_;
        address stakee_;
        uint256 amount_;
    }

    mapping(address => mapping(uint256 => Pending)) private pendings_;

    function pend(uint256 index, uint256 amount, uint128 delay) private returns (address) {
        Pending storage pending = pendings_[msg.sender][index];
        require(pending.expire_ <= block.timestamp + delay);
        address stakee = pending.stakee_;

        if (pending.amount_ == amount)
            delete pendings_[msg.sender][index];
        else {
            require(pending.amount_ > amount);
            pending.amount_ -= amount;
        }

        return stakee;
    }

    function take(uint256 index, uint256 amount, address payable target) external {
        pend(index, amount, 0);
        require(token_.transfer(target, amount));
    }

    function stop(uint256 index, uint256 amount, uint128 delay) external {
        more(pend(index, amount, delay), amount, delay);
    }


    function fixr(Stake storage stake, bytes32 location, Stake storage current) private {
        if (nope(stake.right_))
            return;
        stakes_[name(stake.right_)].parent_ = location;
        copy(current.right_, stake.right_);
        current.after_ = stake.after_;
    }

    function fixl(Stake storage stake, bytes32 location, Stake storage current) private {
        if (nope(stake.left_))
            return;
        stakes_[name(stake.left_)].parent_ = location;
        copy(current.left_, stake.left_);
        current.before_ = stake.before_;
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
            Primary storage child = stake.before_ > stake.after_ ? stake.left_ : stake.right_;

            if (nope(child))
                kill(pivot);
            else {
                Primary storage last = child;
                bytes32 location = name(last);
                Stake storage current = stakes_[location];
                for (;;) {
                    Primary storage next = current.before_ > current.after_ ? current.left_ : current.right_;
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

            emit Delay(stakee, staker, 0);
            delete stakes_[key];
        }

        Pending storage pending = pendings_[msg.sender][index];

        uint256 expire = block.timestamp + delay;
        if (pending.expire_ < expire)
            pending.expire_ = expire;

        if (pending.stakee_ == address(0))
            pending.stakee_ = stakee;
        else
            require(pending.stakee_ == stakee);

        pending.amount_ += amount;
    }

}
