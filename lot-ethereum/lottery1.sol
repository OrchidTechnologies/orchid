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

#define ORC_SHA(a, ...) keccak256(abi.encodePacked(a,## __VA_ARGS__))

#if ORC_ERC
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

#define ORC_ARG , token
#define ORC_POT(s) tokens_[token][s]
#define ORC_PRM(x) , IERC20 x token
#define ORC_SND(r, a) token.transfer(r, a)

contract OrchidLottery1Token {
#else
#define ORC_ARG
#define ORC_POT(s) pots_[s]
#define ORC_PRM(x)
#define ORC_SND(r, a) r.send(a)

contract OrchidLottery1 {
#endif

    struct Pot {
        uint128 amount_;
        uint128 escrow_;

        uint128 warned_;
        uint128 unlock_;

        bytes shared_;
    }

    event Create(address indexed funder, address indexed signer ORC_PRM(indexed));
    event Update(address indexed funder, address indexed signer ORC_PRM(indexed));

    struct Binding {
        OrchidVerifier verify_;
        bytes32 codehash_;
    }

    struct Lottery {
#if ORC_ERC
        mapping(IERC20 => mapping(address => Pot)) tokens_;
#else
        mapping(address => Pot) pots_;
#endif

        uint256 bound_;
        Binding before_;
        Binding after_;
    }

    mapping(address => Lottery) private lotteries_;

    function look(address funder, address signer ORC_PRM()) external view returns (uint128, uint128, uint128, uint256, bytes memory, uint256, Binding memory, Binding memory) {
        Lottery storage lottery = lotteries_[funder];
        Pot storage pot = lottery.ORC_POT(signer);
        return (pot.amount_, pot.escrow_, pot.warned_, pot.unlock_, pot.shared_, lottery.bound_, lottery.before_, lottery.after_);
    }


#if ORC_ERC
    bytes4 constant private Move_ = bytes4(keccak256("move(address,uint256)"));

    function slct(bytes memory data) private pure returns (bytes4 value) {
        assembly { value := mload(add(data, 32)) }
    }

    function move(address signer, IERC20 token, uint256 amount, uint256 adjust_retrieve) external {
        require(token.transferFrom(msg.sender, address(this), amount));
        move_(msg.sender, signer, token, amount, adjust_retrieve);
    }

    function onTokenTransfer(address funder, uint256 amount, bytes calldata data) external returns (bool) {
        require(slct(bytes(data[:4])) == Move_);
        address signer; uint256 adjust_retrieve;
        (signer, adjust_retrieve) = abi.decode(data[4:], (address, uint256));
        move_(funder, signer, IERC20(msg.sender), amount, adjust_retrieve);
        return true;
    }

    function move_(address funder, address signer, IERC20 token, uint256 amount, uint256 adjust_retrieve) private {
#else
    function move(address signer, uint256 adjust_retrieve) external payable {
        address payable funder = msg.sender;
        uint256 amount = msg.value;
#endif

        Pot storage pot = lotteries_[funder].ORC_POT(signer);

        uint256 escrow = pot.escrow_;
        amount += pot.amount_;

        bool create;

    {
        int256 adjust = int256(adjust_retrieve) >> 128;

        if (adjust < 0) {
            uint256 recover = uint256(-adjust);
            uint256 warned = pot.warned_;
            require(pot.unlock_ - 1 < block.timestamp);
            require(recover <= warned);
            amount += recover;
            escrow -= recover;
            warned -= recover;
            if (warned == 0)
                pot.unlock_ = 0;
            pot.warned_ = uint128(warned);
        } else if (adjust != 0) {
            if (escrow == 0)
                create = true;
            uint256 transfer = uint256(adjust);
            require(transfer <= amount);
            amount -= transfer;
            escrow += transfer;
        }
    }

        uint256 retrieve = uint128(adjust_retrieve);

        if (retrieve != 0) {
            require(retrieve <= amount);
            amount -= retrieve;
        }

        pot.escrow_ = uint128(escrow);
        pot.amount_ = uint128(amount);

        if (create)
            emit Create(funder, signer ORC_ARG);
        else
            emit Update(funder, signer ORC_ARG);

        if (retrieve != 0)
#if ORC_ERC
            require(token.transfer(funder, retrieve));
#else
            require(funder.send(retrieve));
#endif
    }

    function warn(address signer ORC_PRM(), uint128 warned) external {
        Pot storage pot = lotteries_[msg.sender].ORC_POT(signer);

        if (warned == 0) {
            pot.warned_ = 0;
            pot.unlock_ = 0;
        } else {
            pot.warned_ = warned;
            pot.unlock_ = uint128(block.timestamp + 1 days);
        }

        emit Update(msg.sender, signer ORC_ARG);
    }


    function name(address signer ORC_PRM(), bytes calldata shared) external {
        Pot storage pot = lotteries_[msg.sender].ORC_POT(signer);
        require(pot.escrow_ == 0);
        pot.shared_ = shared;
        emit Update(msg.sender, signer ORC_ARG);
    }

    event Bound(address indexed funder);

    function bind(OrchidVerifier verify) external {
        Lottery storage lottery = lotteries_[msg.sender];
        require(lottery.bound_ < block.timestamp);

        if (verify == OrchidVerifier(0)) {
            delete lottery.bound_;
            delete lottery.before_;
            delete lottery.after_;
        } else {
            lottery.bound_ = block.timestamp + 1 days;

            lottery.before_ = lottery.after_;

            bytes32 codehash;
            assembly { codehash := extcodehash(verify) }
            lottery.after_.verify_ = verify;
            lottery.after_.codehash_ = codehash;
        }


        emit Bound(msg.sender);
    }


    struct Track {
        uint256 until_;
    }

    mapping(address => mapping(bytes32 => Track)) private tracks_;

    function save(bytes32[] calldata digests) external {
        mapping(bytes32 => Track) storage tracks = tracks_[msg.sender];
        for (uint256 i = digests.length; i != 0; ) {
            Track storage track = tracks[digests[--i]];
            if (track.until_ == 0)
                track.until_ = 1;
        }
    }

    struct Ticket {
        bytes32 reveal; bytes32 salt;
        uint256 issued; bytes32 nonce;
        uint256 amount_ratio;
        uint256 start_range_funder_v;
        bytes receipt;
        bytes32 r; bytes32 s;
    }

    function grab(
        mapping(bytes32 => Track) storage tracks
        ORC_PRM(), address payable recipient,
        Ticket calldata ticket
    ) private returns (uint128) {
        address signer;

        address funder = address(ticket.start_range_funder_v >> 8);
        uint64 start = uint64(ticket.start_range_funder_v >> 192);
        uint128 amount = uint128(ticket.amount_ratio >> 128);
    {
        uint128 ratio = uint128(ticket.amount_ratio);
        uint64 range = uint24(ticket.start_range_funder_v >> 168);

        if (start + range <= block.timestamp)
            return 0;
        if (ratio < uint128(uint256(ORC_SHA(ticket.reveal, ticket.issued, ticket.nonce))))
            return 0;

        bytes32 digest; assembly { digest := chainid() } digest = keccak256(abi.encode(
            ORC_SHA(ORC_SHA(ticket.reveal), ticket.salt, recipient), ticket.issued, ticket.nonce,
            ticket.amount_ratio, ticket.start_range_funder_v & uint256(~0xff) ORC_ARG, this, digest));
        signer = ecrecover(digest, uint8(ticket.start_range_funder_v), ticket.r, ticket.s);

    {
        Track storage track = tracks[bytes32(uint256(signer)) ^ digest];
        if (track.until_ != 0)
            return 0;
        track.until_ = start + range;
    }

        if (start < block.timestamp) {
            uint128 limit = uint128(uint256(amount) * (range - (block.timestamp - start)) / range);
            if (amount > limit)
                amount = limit;
        }
    }

        Lottery storage lottery = lotteries_[funder];
        Pot storage pot = lottery.ORC_POT(signer);

    {
        uint128 cache = pot.amount_;

        if (cache >= amount) {
            cache -= amount;
            pot.amount_ = cache;
        } else {
            amount = cache;
            pot.amount_ = 0;
            pot.escrow_ = 0;
        }

        emit Update(funder, signer ORC_ARG);
    }

        uint256 bound = lottery.bound_;
        if (bound != 0) {
            Binding storage binding = block.timestamp < bound ? lottery.before_ : lottery.after_;
            OrchidVerifier verify = binding.verify_;
            if (verify != OrchidVerifier(0)) {
                bytes32 codehash; assembly { codehash := extcodehash(verify) }
                if (codehash == binding.codehash_)
                    verify.book(pot.shared_, recipient, ticket.receipt);
            }
        }

        return amount;
    }

    function grab(address payable recipient ORC_PRM(), Ticket[] calldata tickets, bytes32[] calldata digests) external {
        mapping(bytes32 => Track) storage tracks = tracks_[recipient];

        uint256 segment; assembly { segment := mload(0x40) }

        uint128 amount = 0;
        for (uint256 i = tickets.length; i != 0; ) {
            amount += grab(tracks ORC_ARG, recipient, tickets[--i]);
            assembly { mstore(0x40, segment) }
        }

        require(ORC_SND(recipient, amount));

        for (uint256 i = digests.length; i != 0; ) {
            Track storage track = tracks[digests[--i]];
            if (track.until_ <= block.timestamp)
                delete track.until_;
        }
    }

    function grab(address payable recipient ORC_PRM(), Ticket calldata ticket, bytes32 digest) external {
        mapping(bytes32 => Track) storage tracks = tracks_[recipient];

        require(ORC_SND(recipient, grab(tracks ORC_ARG, recipient, ticket)));

        if (digest != 0) {
            Track storage track = tracks[digest];
            if (track.until_ <= block.timestamp)
                delete track.until_;
        }
    }
}
