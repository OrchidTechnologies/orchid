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

interface OrchidVerifier {
    function good(bytes calldata shared, address target, bytes calldata receipt) external pure returns (bool);
}

contract OrchidLottery {

    IERC20 internal token_;

    constructor(IERC20 token) public {
        token_ = token;
    }

    function what() external view returns (IERC20) {
        return token_;
    }


    struct Pot {
        uint256 offset_;

        uint128 amount_;
        uint128 escrow_;

        uint256 unlock_;

        OrchidVerifier verify_;
        bytes32 codehash_;
        bytes shared_;
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

    function kill(address signer) external {
        address funder = msg.sender;
        Lottery storage lottery = lotteries_[funder];
        Pot storage pot = lottery.pots_[signer];
        require(pot.offset_ != 0);
        address key = lottery.keys_[lottery.keys_.length - 1];
        lottery.pots_[key].offset_ = pot.offset_;
        lottery.keys_[pot.offset_ - 1] = key;
        --lottery.keys_.length;
        delete lottery.pots_[signer];
        send(funder, signer, pot);
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
        require(offset <= all.length);
        if (count > all.length - offset)
            count = all.length - offset;
        address[] memory slice = new address[](count);
        for (uint256 i = 0; i != count; ++i)
            slice[i] = all[offset + i];
        return slice;
    }


    function look(address funder, address signer) external view returns (uint128, uint128, uint256, OrchidVerifier, bytes32, bytes memory) {
        Pot storage pot = lotteries_[funder].pots_[signer];
        return (pot.amount_, pot.escrow_, pot.unlock_, pot.verify_, pot.codehash_, pot.shared_);
    }


    function push(address signer, uint128 total, uint128 escrow) external {
        address funder = msg.sender;
        require(total >= escrow);
        Pot storage pot = find(funder, signer);
        if (pot.offset_ == 0)
            pot.offset_ = lotteries_[funder].keys_.push(signer);
        pot.amount_ += total - escrow;
        pot.escrow_ += escrow;
        send(funder, signer, pot);
        require(token_.transferFrom(funder, address(this), total));
    }

    function move(address signer, uint128 amount) external {
        address funder = msg.sender;
        Pot storage pot = find(funder, signer);
        require(pot.amount_ >= amount);
        amount = take(amount, pot);
        pot.escrow_ += amount;
        send(funder, signer, pot);
    }

    function burn(address signer, uint128 escrow) external {
        address funder = msg.sender;
        Pot storage pot = find(funder, signer);
        if (escrow > pot.escrow_)
            escrow = pot.escrow_;
        pot.escrow_ -= escrow;
        send(funder, signer, pot);
    }

    function bind(address signer, OrchidVerifier verify, bytes calldata shared) external {
        address funder = msg.sender;
        Pot storage pot = find(funder, signer);
        require(pot.escrow_ == 0);

        bytes32 codehash;
        assembly { codehash := extcodehash(verify) }

        pot.verify_ = verify;
        pot.codehash_ = codehash;
        pot.shared_ = shared;
    }


    struct Track {
        uint256 until_;
    }

    mapping(address => mapping(bytes32 => Track)) internal tracks_;


    function take(uint128 amount, Pot storage pot) private returns (uint128) {
        if (pot.amount_ >= amount)
            pot.amount_ -= amount;
        else {
            amount = pot.amount_;
            pot.escrow_ = 0;
        }

        return amount;
    }

    function take(address funder, address signer, uint128 amount, address payable target, Pot storage pot) private {
        amount = take(amount, pot);
        send(funder, signer, pot);

        if (amount != 0)
            require(token_.transfer(target, amount));
    }

    function take(address funder, address signer, uint128 amount, address payable target, bytes memory receipt) private {
        Pot storage pot = find(funder, signer);
        take(funder, signer, amount, target, pot);

        OrchidVerifier verify = pot.verify_;
        if (verify != OrchidVerifier(0)) {
            bytes32 codehash;
            assembly { codehash := extcodehash(verify) }
            if (pot.codehash_ == codehash)
                require(verify.good(pot.shared_, target, receipt));
        }
    }

    // the arguments to this function are carefully ordered for stack depth optimization
    // this function was marked public, instead of external, for lower stack depth usage
    function grab(
        bytes32 reveal, bytes32 commit,
        uint8 v, bytes32 r, bytes32 s,
        bytes32 nonce, address funder,
        uint128 amount, uint128 ratio,
        uint256 start, uint128 range,
        address payable target, bytes memory receipt,
        bytes32[] memory old
    ) public {
        require(keccak256(abi.encodePacked(reveal)) == commit);
        require(uint256(keccak256(abi.encodePacked(reveal, nonce))) >> 128 <= ratio);

        bytes32 ticket = keccak256(abi.encode(commit, nonce, funder, amount, ratio, start, range, target, receipt));
        address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", ticket)), v, r, s);
        require(signer != address(0));

        {
            mapping(bytes32 => Track) storage tracks = tracks_[target];

            {
                Track storage track = tracks[keccak256(abi.encodePacked(signer, ticket))];
                uint256 until = start + range;
                require(until > block.timestamp);
                require(track.until_ == 0);
                track.until_ = until;
            }

            for (uint256 i = 0; i != old.length; ++i) {
                Track storage track = tracks[old[i]];
                if (track.until_ <= block.timestamp)
                    delete track.until_;
            }
        }

        if (start < block.timestamp) {
            uint128 limit = uint128(uint256(amount) * (range - (block.timestamp - start)) / range);
            if (amount > limit)
                amount = limit;
        }

        take(funder, signer, amount, target, receipt);
    }

    function give(address funder, address payable target, uint128 amount, bytes calldata receipt) external {
        address signer = msg.sender;
        take(funder, signer, amount, target, receipt);
    }

    function pull(address signer, address payable target, uint128 amount) external {
        address funder = msg.sender;
        Pot storage pot = find(funder, signer);
        take(funder, signer, amount, target, pot);
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

    function pull(address signer, address payable target, uint128 amount, uint128 escrow) external {
        address funder = msg.sender;
        Pot storage pot = find(funder, signer);
        if (amount > pot.amount_)
            amount = pot.amount_;
        if (escrow > pot.escrow_)
            escrow = pot.escrow_;
        if (escrow != 0)
            require(pot.unlock_ - 1 < block.timestamp);
        uint128 total = amount + escrow;
        pot.amount_ -= amount;
        pot.escrow_ -= escrow;
        if (pot.escrow_ == 0)
            pot.unlock_ = 0;
        send(funder, signer, pot);
        require(token_.transfer(target, total));
    }

    function yank(address signer, address payable target) external {
        address funder = msg.sender;
        Pot storage pot = find(funder, signer);
        if (pot.escrow_ != 0)
            require(pot.unlock_ - 1 < block.timestamp);
        uint128 total = pot.amount_ + pot.escrow_;
        pot.amount_ = 0;
        pot.escrow_ = 0;
        pot.unlock_ = 0;
        send(funder, signer, pot);
        require(token_.transfer(target, total));
    }
}
