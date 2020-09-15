/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2019  The Orchid Authors
*/

/* GNU Affero General Public License, Version 3 {{{ */
/* SPDX-License-Identifier: AGPL-3.0-or-later */
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


pragma solidity 0.7.1;
pragma experimental ABIEncoderV2;

import "./include.sol";

contract OrchidLottery1 {

    struct Pot {
        uint128 amount_;
        uint128 escrow_;

        uint128 warned_;
        uint128 unlock_;
    }

    event Update(address indexed funder, address indexed signer);


    struct Lottery {
        mapping(address => Pot) pots_;

        uint256 bound_;
        OrchidVerifier verify_;
        bytes32 codehash_;
        bytes shared_;
    }

    mapping(address => Lottery) private lotteries_;


    function find(address funder, address signer) private view returns (Pot storage) {
        return lotteries_[funder].pots_[signer];
    }


    function look(address funder, address signer) external view returns (uint128, uint128, uint128, uint256, OrchidVerifier, bytes32, bytes memory) {
        Lottery storage lottery = lotteries_[funder];
        Pot storage pot = lottery.pots_[signer];
        return (pot.amount_, pot.escrow_, pot.warned_, pot.unlock_, lottery.verify_, lottery.codehash_, lottery.shared_);
    }


    function move(address signer, uint256 recover, uint256 transfer, uint256 retrieve) external payable {
        Pot storage pot = find(msg.sender, signer);

        uint256 escrow = pot.escrow_;
        uint256 amount = pot.amount_ + msg.value;

        if (recover != 0) {
            uint256 warned = pot.warned_;
            require(pot.unlock_ - 1 < block.timestamp);
            require(recover <= warned);
            amount += recover;
            escrow -= recover;
            warned -= recover;
            if (warned == 0)
                pot.unlock_ = 0;
            pot.warned_ = uint128(warned);
        }

        if (transfer != 0) {
            require(transfer <= amount);
            amount -= transfer;
            escrow += transfer;
        }

        if (retrieve != 0) {
            require(retrieve <= amount);
            amount -= retrieve;
        }

        pot.escrow_ = uint128(escrow);
        pot.amount_ = uint128(amount);

        emit Update(msg.sender, signer);

        if (retrieve != 0)
            require(msg.sender.send(retrieve));
    }

    event Bound(address indexed funder);

    function bind(OrchidVerifier verify, bytes calldata shared) external {
        Lottery storage lottery = lotteries_[msg.sender];

        bytes32 codehash;
        assembly { codehash := extcodehash(verify) }

        lottery.bound_ = block.timestamp + 1 days;
        lottery.verify_ = verify;
        lottery.codehash_ = codehash;
        lottery.shared_ = shared;

        emit Bound(msg.sender);
    }


    struct Track {
        uint256 until_;
    }

    mapping(address => mapping(bytes32 => Track)) private tracks_;

    struct Ticket {
        bytes32 reveal; bytes32 salt;
        uint256 issued; bytes32 nonce;
        uint256 start; uint128 range;
        uint128 amount; uint128 ratio;
        address funder; bytes receipt;
        uint8 v; bytes32 r; bytes32 s;
    }

    function grab(
        mapping(bytes32 => Track) storage tracks,
        address payable recipient,
        Ticket calldata ticket
    ) private returns (uint128) {
        address signer;

        uint128 amount = ticket.amount;
        address funder = ticket.funder;
    {
        uint128 range = ticket.range;
        uint128 ratio = ticket.ratio;

        if (ticket.start + range <= block.timestamp)
            return 0;
        if (ratio < uint128(uint256(keccak256(abi.encodePacked(ticket.reveal, ticket.issued, ticket.nonce)))))
            return 0;

        bytes32 digest; assembly { digest := chainid() } digest = keccak256(abi.encode(
            keccak256(abi.encodePacked(keccak256(abi.encodePacked(ticket.reveal)), ticket.salt, recipient)),
            this, digest, ticket.issued, ticket.nonce, ticket.start, range, amount, ratio, funder));
        signer = ecrecover(digest, ticket.v, ticket.r, ticket.s);

    {
        Track storage track = tracks[bytes32(uint256(signer)) ^ digest];
        if (track.until_ != 0)
            return 0;
        track.until_ = ticket.start + range;
    }

        if (ticket.start < block.timestamp) {
            uint128 limit = uint128(uint256(amount) * (range - (block.timestamp - ticket.start)) / range);
            if (amount > limit)
                amount = limit;
        }
    }

        Lottery storage lottery = lotteries_[funder];

    {
        Pot storage pot = lottery.pots_[signer];
        uint128 cache = pot.amount_;

        if (cache >= amount) {
            cache -= amount;
            pot.amount_ = cache;
        } else {
            amount = cache;
            pot.amount_ = 0;
            pot.escrow_ = 0;
        }

        emit Update(funder, signer);
    }

        if (block.timestamp > lottery.bound_ - 1) {
            OrchidVerifier verify = lottery.verify_;
            if (verify != OrchidVerifier(0)) {
                bytes32 codehash; assembly { codehash := extcodehash(verify) }
                if (codehash == lottery.codehash_)
                    verify.book(lottery.shared_, recipient, ticket.receipt);
            }
        }

        return amount;
    }

    function grab(address payable recipient, Ticket[] calldata tickets, bytes32[] calldata old) external {
        mapping(bytes32 => Track) storage tracks = tracks_[recipient];

        uint256 segment; assembly { segment := mload(0x40) }

        uint128 amount = 0;
        for (uint256 i = tickets.length; i != 0; ) {
            amount += grab(tracks, recipient, tickets[--i]);
            assembly { mstore(0x40, segment) }
        }

        require(recipient.send(amount));

        for (uint256 i = old.length; i != 0; ) {
            Track storage track = tracks[old[--i]];
            if (track.until_ <= block.timestamp)
                delete track.until_;
        }
    }

    function grab(address payable recipient, Ticket calldata ticket) external {
        mapping(bytes32 => Track) storage tracks = tracks_[recipient];
        require(recipient.send(grab(tracks, recipient, ticket)));
    }


    function warn(address signer, uint128 warned) external {
        Pot storage pot = find(msg.sender, signer);

        if (warned == 0) {
            pot.warned_ = 0;
            pot.unlock_ = 0;
        } else {
            pot.warned_ = warned;
            pot.unlock_ = uint128(block.timestamp + 1 days);
        }

        emit Update(msg.sender, signer);
    }
}
