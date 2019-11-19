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

contract OrchidLottery {

    IERC20 internal token_;

    constructor(address token) public {
        token_ = IERC20(token);
    }


    struct Pot {
        uint256 offset_;

        uint128 amount_;
        uint128 escrow_;

        uint256 unlock_;
    }

    event Update(address indexed funder, address indexed signer, uint128 amount, uint128 escrow, uint256 unlock);

    function send(address funder, address signer, Pot storage pot) private {
        emit Update(funder, signer, pot.amount_, pot.escrow_, pot.unlock_);
    }


    struct Lottery {
        address[] keys_;
        mapping(address => Pot) pots_;
    }

    mapping(address => Lottery) internal lotteries_;


    function find(address funder, address signer) private view returns (Pot storage) {
        return lotteries_[funder].pots_[signer];
    }

    function kill(address funder, address signer, Pot storage pot) private {
        Lottery storage lottery = lotteries_[funder];
        require(pot.offset_ != 0);
        address key = lottery.keys_[lottery.keys_.length - 1];
        lottery.pots_[key].offset_ = pot.offset_;
        lottery.keys_[pot.offset_ - 1] = key;
        --lottery.keys_.length;
        delete lottery.pots_[signer];
    }


    function size(address funder) external view returns (uint256) {
        return lotteries_[funder].keys_.length;
    }

    function keys(address funder) external view returns (address[] memory) {
        return lotteries_[funder].keys_;
    }

    function seek(address funder, uint256 offset) external view returns (address) {
        return lotteries_[funder].keys_[offset];
    }

    function page(address funder, uint256 offset, uint256 count) external view returns (address[] memory) {
        address[] storage all = lotteries_[funder].keys_;
        address[] memory slice = new address[](count);
        for (uint256 i = 0; i != count; ++i)
            slice[i] = all[offset + i];
        return slice;
    }


    function look(address funder, address signer) external view returns (uint128, uint128, uint256) {
        Pot storage pot = lotteries_[funder].pots_[signer];
        return (pot.amount_, pot.escrow_, pot.unlock_);
    }


    function push(address signer, uint128 amount, uint128 total) external {
        address funder = msg.sender;
        require(total >= amount);
        Pot storage pot = find(funder, signer);
        if (pot.offset_ == 0)
            pot.offset_ = lotteries_[funder].keys_.push(signer);
        pot.amount_ += amount;
        pot.escrow_ += total - amount;
        send(funder, signer, pot);
        require(token_.transferFrom(funder, address(this), total));
    }

    function move(address signer, uint128 amount) external {
        address funder = msg.sender;
        Pot storage pot = find(funder, signer);
        require(pot.amount_ >= amount);
        pot.amount_ -= amount;
        pot.escrow_ += amount;
        send(funder, signer, pot);
    }


    struct Track {
        uint256 until_;
    }

    mapping(address => mapping(bytes32 => Track)) internal tracks_;

    function kill(Track storage track) private {
        require(track.until_ <= block.timestamp);
        delete track.until_;
    }

    function kill(bytes32 ticket) external {
        kill(tracks_[msg.sender][ticket]);
    }


    function take(address funder, address signer, uint128 amount, address payable target) private {
        Pot storage pot = find(funder, signer);

        if (pot.amount_ >= amount)
            pot.amount_ -= amount;
        else {
            amount = pot.amount_;
            kill(funder, signer, pot);
        }

        send(funder, signer, pot);

        if (amount != 0)
            require(token_.transfer(target, amount));
    }

    function grab(bytes32 seed, bytes32 hash, bytes32 nonce, uint256 start, uint128 range, uint128 amount, uint128 ratio, address funder, address payable target, uint8 v, bytes32 r, bytes32 s, bytes32[] calldata old) external {
        require(keccak256(abi.encodePacked(seed)) == hash);
        require(uint256(keccak256(abi.encodePacked(seed, nonce))) >> 128 <= ratio);

        bytes32 ticket = keccak256(abi.encode(hash, nonce, start, range, amount, ratio, funder, target));

        {
            mapping(bytes32 => Track) storage tracks = tracks_[target];

            Track storage track = tracks[ticket];
            uint256 until = start + range;
            require(until > block.timestamp);
            require(track.until_ == 0);
            track.until_ = until;

            for (uint256 i = 0; i != old.length; ++i)
                kill(tracks[old[i]]);
        }

        if (start < block.timestamp) {
            uint128 limit = uint128(uint256(amount) * (range - (block.timestamp - start)) / range);
            if (amount > limit)
                amount = limit;
        }

        address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", ticket)), v, r, s);
        require(signer != address(0));
        take(funder, signer, amount, target);
    }

    function give(address funder, address payable target, uint128 amount) external {
        address signer = msg.sender;
        take(funder, signer, amount, target);
    }

    function pull(address signer, address payable target, uint128 amount) external {
        address funder = msg.sender;
        take(funder, signer, amount, target);
    }


    function warn(address signer) external {
        address funder = msg.sender;
        Pot storage pot = find(funder, signer);
        pot.unlock_ = block.timestamp + 1 days;
        send(funder, signer, pot);
    }

    function lock(address signer) external {
        address funder = msg.sender;
        Pot storage pot = find(funder, signer);
        pot.unlock_ = 0;
        send(funder, signer, pot);
    }

    function pull(address signer, address payable target) external {
        address funder = msg.sender;
        Pot storage pot = find(funder, signer);
        require(pot.unlock_ != 0);
        require(pot.unlock_ <= block.timestamp);
        uint128 amount = pot.amount_ + pot.escrow_;
        kill(funder, signer, pot);
        send(funder, signer, pot);
        require(token_.transfer(target, amount));
    }
}
