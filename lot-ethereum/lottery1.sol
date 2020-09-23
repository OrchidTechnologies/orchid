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

#define ORC_CAT(a, b) a ## b
#define ORC_DAY (block.timestamp + 1 days)
#define ORC_SHA(a, ...) keccak256(abi.encodePacked(a,## __VA_ARGS__))

#if defined(ORC_SYM) && !defined(ORC_ERC)
#define ORC_ARG , token
#define ORC_ARR [token]
#define ORC_PRM(x) , IERC20 x token
#define ORC_SUF(n, s) n ## tok
#define ORC_TOK token
#else
#define ORC_ARG
#define ORC_ARR
#define ORC_PRM(x)
#if defined(ORC_SYM)
#define ORC_SUF(n, s) ORC_CAT(n, s)
#else
#define ORC_SUF(n, s) n ## eth
#endif
#define ORC_TOK IERC20(ORC_ERC)
#endif

#if defined(ORC_SYM)
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

#define ORC_SND(r, a) { \
    (bool _s, bytes memory _d) = address(ORC_TOK).call( \
        abi.encodeWithSignature("transfer(address,uint256)", r, a)); \
    require(_s && (_d.length == 0 || abi.decode(_d, (bool)))); \
}
#else
#define ORC_SND(r, a) { \
    (bool _s,) = r.call{value: a}(""); \
    require(_s); \
}
#endif

contract ORC_SUF(OrchidLottery1, ORC_SYM) {
    struct Pot {
        uint128 amount_;
        uint128 escrow_;

        uint128 warned_;
        uint128 unlock_;
    }

    event Create(address indexed funder, address indexed signer ORC_PRM(indexed));
    event Update(address indexed funder, address indexed signer ORC_PRM(indexed));

    struct Lottery {
#if defined(ORC_SYM) && !defined(ORC_ERC)
        mapping(address => mapping(IERC20 => Pot)) pots_;
#else
        mapping(address => Pot) pots_;
#endif

        uint256 bound_;
        mapping(address => uint256) players_;
    }

    mapping(address => Lottery) private lotteries_;

    function look(address funder, address signer ORC_PRM()) external view returns (uint128, uint128, uint128, uint256, uint256) {
        Lottery storage lottery = lotteries_[funder];
        Pot storage pot = lottery.pots_[signer]ORC_ARR;
        return (pot.amount_, pot.escrow_, pot.warned_, pot.unlock_, lottery.bound_);
    }


    function safe(uint256 value) private pure returns (uint128) {
        uint128 result = uint128(value);
        require(uint256(result) == value);
        return result;
    }

#if defined(ORC_SYM)
    bytes4 constant private Move_ = bytes4(keccak256("move(address,uint256)"));

    function move(address signer ORC_PRM(), uint256 amount, uint256 adjust_retrieve) external {
        (bool _s, bytes memory _d) = address(ORC_TOK).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount));
        require(_s && abi.decode(_d, (bool)));

        move_(msg.sender, signer ORC_ARG, amount, adjust_retrieve);
    }

    function tokenFallback(address funder, uint256 amount, bytes calldata data) public {
#if defined(ORC_ERC)
        require(IERC20(msg.sender) == IERC20(ORC_ERC));
#else
        IERC20 token = IERC20(msg.sender);
#endif
        if (data.length == 0) {
            Pot storage pot = lotteries_[funder].pots_[funder]ORC_ARR;
            pot.amount_ = safe(pot.amount_ + amount);
        } else {
            // XXX: this should be calldataload(data.offset), maybe with an add or a shr in there
            bytes memory copy = data; bytes4 selector; assembly { selector := mload(add(copy, 32)) }
            require(selector == Move_);
            address signer; uint256 adjust_retrieve;
            (signer, adjust_retrieve) = abi.decode(data[4:], (address, uint256));
            move_(funder, signer ORC_ARG, amount, adjust_retrieve);
        }
    }

    function onTokenTransfer(address funder, uint256 amount, bytes calldata data) external returns (bool) {
        tokenFallback(funder, amount, data);
        return true;
    }

    function move_(address funder, address signer ORC_PRM(), uint256 amount, uint256 adjust_retrieve) private {
#else
    receive() external payable {
        Pot storage pot = lotteries_[msg.sender].pots_[msg.sender]ORC_ARR;
        pot.amount_ = safe(pot.amount_ + msg.value);
    }

    function move(address signer, uint256 adjust_retrieve) external payable {
        address payable funder = msg.sender;
        uint256 amount = msg.value;
#endif

        Pot storage pot = lotteries_[funder].pots_[signer]ORC_ARR;

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
            ORC_SND(funder, retrieve)
    }

    function warn(address signer ORC_PRM(), uint128 warned) external {
        Pot storage pot = lotteries_[msg.sender].pots_[signer]ORC_ARR;

        if (warned == 0) {
            pot.warned_ = 0;
            pot.unlock_ = 0;
        } else {
            pot.warned_ = warned;
            pot.unlock_ = uint128(ORC_DAY);
        }

        emit Update(msg.sender, signer ORC_ARG);
    }


    event Bound(address indexed funder);

    function bind(bool allow, address[] calldata recipients) external {
        Lottery storage lottery = lotteries_[msg.sender];

        uint i = recipients.length;
        if (i == 0)
            lottery.bound_ = allow ? 0 : ORC_DAY;
        else {
            uint256 value = allow ? uint256(-1) :
                lottery.bound_ < block.timestamp ? 0 : ORC_DAY;
            do lottery.players_[recipients[--i]] = value;
            while (i != 0);
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

    #define ORC_DEL(d) { \
        Track storage track = tracks[d]; \
        if (track.until_ <= block.timestamp) \
            delete track.until_; \
    }


    /*struct Packed {
        uint64 start;
        uint24 range;
        address funder;
        uint8 v;
    }*/

    struct Ticket {
        bytes32 reveal; bytes32 salt;
        uint256 issued_nonce;
        uint256 amount_ratio;
        uint256 packed;
        bytes32 r; bytes32 s;
    }

    function grab(
        mapping(bytes32 => Track) storage tracks,
        uint256 destination ORC_PRM(),
        Ticket calldata ticket
    ) private returns (uint256) {
        bytes32 digest; assembly { digest := chainid() } digest = keccak256(abi.encode(
            ORC_SHA(ORC_SHA(ticket.reveal), ticket.salt, destination), ticket.issued_nonce,
            ticket.amount_ratio, ticket.packed & ~uint256(uint8(-1)) ORC_ARG, this, digest));
        address signer = ecrecover(digest, uint8(ticket.packed), ticket.r, ticket.s);

        uint256 amount = uint128(ticket.amount_ratio >> 128);
    {{
        uint256 ratio = uint128(ticket.amount_ratio);
        if (ratio < uint128(uint256(ORC_SHA(ticket.reveal, ticket.issued_nonce))))
            return 0;
    }
        address funder = address(ticket.packed >> 8);
    {
        uint256 start = ticket.packed >> 192;
        uint256 range = uint24(ticket.packed >> 168);

        if (start + range <= block.timestamp)
            return 0;
        if (start < block.timestamp) {
            uint256 limit = amount * (range - (block.timestamp - start)) / range;
            if (amount > limit)
                amount = limit;
        }

        Track storage track = tracks[bytes32(uint256(signer)) ^ digest];
        if (track.until_ != 0)
            return 0;
        track.until_ = start + range;
    }{
        Lottery storage lottery = lotteries_[funder];
        if (lottery.bound_ - 1 < block.timestamp)
            require(block.timestamp < lottery.players_[address(destination)]);
    {
        Pot storage pot = lottery.pots_[signer]ORC_ARR;
        uint256 cache = pot.amount_;

        if (cache >= amount) {
            cache -= amount;
            pot.amount_ = uint128(cache);
        } else {
            amount = cache;
            pot.amount_ = 0;
            pot.escrow_ = 0;
        }
    }}
        emit Update(funder, signer ORC_ARG);
    }
        return amount;
    }

    #define ORC_GRB \
        address payable recipient = address(destination); \
        mapping(bytes32 => Track) storage tracks = tracks_[recipient];

    #define ORC_DST(amount) \
        if (destination >> 160 == 0) \
            ORC_SND(recipient, amount) \
        else \
            lotteries_[recipient].pots_[recipient]ORC_ARR.amount_ += uint128(amount);

    function grab(uint256 destination ORC_PRM(), Ticket[] calldata tickets, bytes32[] calldata digests) external {
        ORC_GRB

        uint256 segment; assembly { segment := mload(0x40) }

        uint256 amount = 0;
        for (uint256 i = tickets.length; i != 0; ) {
            amount += grab(tracks, destination ORC_ARG, tickets[--i]);
            assembly { mstore(0x40, segment) }
        }

        ORC_DST(amount)

        for (uint256 i = digests.length; i != 0; )
            ORC_DEL(digests[--i])
    }

    function grab(uint256 destination ORC_PRM(), Ticket calldata ticket, bytes32 digest) external {
        ORC_GRB

        ORC_DST(grab(tracks, destination ORC_ARG, ticket))

        if (digest != 0)
            ORC_DEL(digest)
    }
}
