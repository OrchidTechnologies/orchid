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


contract ContinuousDistributor {

    IERC20 internal token_;

    address owner_;

    struct Linear {
        uint    beg_;
        uint    end_;
        uint128 amt_;
    }

    mapping(address => Linear []) limits_;
    mapping(address => uint) lastup_;
    address [] recipients_;
    uint i_;


    constructor(IERC20 token) public {
        token_ = token;
        owner_ = msg.sender;
        i_     = 0;
    }

    function what() external view returns (IERC20) {
        return token_;
    }

    function update(address rec, uint idx, uint beg, uint end, uint128 amt) public {
        require(msg.sender == owner_);
        if (lastup_[rec] == 0) {
            recipients_.push(rec);
            lastup_[rec] = 1;
        }
        while (idx >= limits_[rec].length) {
            limits_[rec].push(Linear(0,0,0));
        }
        Linear storage func = limits_[rec][idx];
        func.beg_ = beg;
        func.end_ = end;
        func.amt_ = amt;
    }

    function calculate_(Linear memory f, uint t) private pure returns (uint128) {
        t = t > f.beg_ ? t : f.beg_;
        t = t < f.end_ ? t : f.end_;
        uint128 amt = uint128( (uint256(f.amt_) * uint256(t - f.beg_)) / uint256(f.end_ - f.beg_) );
        return amt;
    }

    function calculate(address a, uint t) private view returns (uint128) {
        Linear [] memory limits = limits_[a];
        if (limits.length == 0) return 0;
        uint128 amt = uint128(-1);
        for (uint i = 0; i < limits.length; i++) {
           uint128 x = calculate_(limits[i], t);
           amt = amt < x ? amt : x;
        }
        if (amt == uint128(-1)) amt = 0;
        return amt;
    }

    function compute_owed_(address a, uint t) public view returns (uint128) {
        uint lt = lastup_[a];
        uint128 total = calculate(a, t);
        uint128 sent  = calculate(a, lt);
        sent = sent > total ? total : sent;
        return total - sent;
    }

    function compute_owed(address a) public view returns (uint128) {
        uint t = block.timestamp;
        return compute_owed_(a,t);
    }

    function distribute(address recipient, uint t) private {
        uint128 amt = compute_owed_(recipient, t);
        if (amt != 0)
            require(token_.transfer(recipient, amt));
        lastup_[recipient] = t;
    }

    function distribute_all() public {
        uint t = block.timestamp;
        for (uint i = 0; i < recipients_.length; i++) {
            address recipient = recipients_[i];
            distribute(recipient, t);
        }
    }

    function distribute_partial(uint N) public {
        N = N > 8 ? N : 8;
        N = N < recipients_.length ? N : recipients_.length;
        uint t = block.timestamp;
        for (uint i = 0; i < N; i++) {
            address recipient = recipients_[(i + i_) % recipients_.length];
            distribute(recipient, t);
        }
        i_ += N;
    }



}
