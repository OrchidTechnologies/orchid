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


pragma solidity 0.7.2;
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
interface IERC20 {}

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
        uint256 escrow_amount_;
        uint256 unlock_warned_;
    }

    #define ORC_WRN(u, w) (w == 0 ? 0 : u << 128 | w)

    event Create(address indexed funder, address indexed signer ORC_PRM(indexed));
    event Update(address indexed funder, address indexed signer ORC_PRM(indexed));
    event Delete(address indexed funder, address indexed signer ORC_PRM(indexed));

    struct Lottery {
#if defined(ORC_SYM) && !defined(ORC_ERC)
        mapping(address => mapping(IERC20 => Pot)) pots_;
#else
        mapping(address => Pot) pots_;
#endif

        uint256 bound_;
        mapping(address => uint256) recipients_;
    }

    mapping(address => Lottery) private lotteries_;

    function read(address funder, address signer, address recipient ORC_PRM()) external view returns (uint256, uint256, uint256) {
        Lottery storage lottery = lotteries_[funder];
        Pot storage pot = lottery.pots_[signer]ORC_ARR;
        return (pot.escrow_amount_, pot.unlock_warned_, lottery.bound_ << 128 | lottery.recipients_[recipient]);
    }

    #define ORC_POT(f, s) \
        lotteries_[f].pots_[s]ORC_ARR

    #define ORC_GFT(f, s, a) { \
        Pot storage pot = ORC_POT(f, s); \
        uint256 cache = pot.escrow_amount_; \
        require(uint128(cache) + a >> 128 == 0); \
        pot.escrow_amount_ = cache + a; \
    }


#if defined(ORC_SYM)
    #define ORC_FRM(a) { \
        (bool _s, bytes memory _d) = address(ORC_TOK).call( \
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), a)); \
        require(_s && abi.decode(_d, (bool))); \
    }

    function gift(address funder, address signer ORC_PRM(), uint256 amount) external {
        ORC_FRM(amount)
        ORC_GFT(funder, signer, amount)
    }

    function move(address signer ORC_PRM(), uint256 amount, uint256 adjust_retrieve) external {
        ORC_FRM(amount)
        move(msg.sender, signer ORC_ARG, amount, adjust_retrieve);
    }

    bytes4 constant private Move_ = bytes4(keccak256("move(address,uint256)"));
    bytes4 constant private Gift_ = bytes4(keccak256("gift(address,address)"));

    function tokenFallback(address sender, uint256 amount, bytes calldata data) public {
#if defined(ORC_ERC)
        require(IERC20(msg.sender) == IERC20(ORC_ERC));
#else
        IERC20 token = IERC20(msg.sender);
#endif
        if (data.length == 0)
            ORC_POT(sender, sender).escrow_amount_ += amount;
        else {
            // XXX: this should be calldataload(data.offset), maybe with an add or a shr in there
            bytes memory copy = data; bytes4 selector; assembly { selector := mload(add(copy, 32)) }
            if (false) {
            } else if (selector == Move_) {
                address signer; uint256 adjust_retrieve;
                (signer, adjust_retrieve) = abi.decode(data[4:], (address, uint256));
                move(sender, signer ORC_ARG, amount, adjust_retrieve);
            } else if (selector == Gift_) {
                address funder; address signer;
                (funder, signer) = abi.decode(data[4:], (address, address));
                ORC_GFT(funder, signer, amount)
            } else require(false);
        }
    }

    function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external returns (bool) {
        tokenFallback(sender, amount, data);
        return true;
    }

    function move(address funder, address signer ORC_PRM(), uint256 amount, uint256 adjust_retrieve) private {
#else
    receive() external payable {
        ORC_POT(msg.sender, msg.sender).escrow_amount_ += msg.value;
    }

    function gift(address funder, address signer) external payable {
        ORC_GFT(funder, signer, msg.value)
    }

    function move(address signer, uint256 adjust_retrieve) external payable {
        address payable funder = msg.sender;
        uint256 amount = msg.value;
#endif
        Pot storage pot = ORC_POT(funder, signer);

        uint256 escrow = pot.escrow_amount_;
        amount += uint128(escrow);
        escrow = escrow >> 128;
    {
        bool create;

        int256 adjust = int256(adjust_retrieve) >> 128;
        if (adjust < 0) {
            uint256 warned = pot.unlock_warned_;
            uint256 unlock = warned >> 128;
            warned = uint128(warned);

            uint256 recover = uint256(-adjust);
            require(recover <= escrow);
            amount += recover;
            escrow -= recover;

            require(recover <= warned);
            require(unlock - 1 < block.timestamp);
            pot.unlock_warned_ = ORC_WRN(unlock, warned - recover);
        } else if (adjust != 0) {
            if (escrow == 0)
                create = true;

            uint256 transfer = uint256(adjust);
            require(transfer <= amount);
            amount -= transfer;
            escrow += transfer;
        }

        if (create)
            emit Create(funder, signer ORC_ARG);
        else
            emit Update(funder, signer ORC_ARG);
    }
        uint256 retrieve = uint128(adjust_retrieve);
        if (retrieve != 0) {
            require(retrieve <= amount);
            amount -= retrieve;
        }

        pot.escrow_amount_ = escrow << 128 | amount;

        if (retrieve != 0)
            ORC_SND(funder, retrieve)
    }

    function warn(address signer ORC_PRM(), uint128 warned) external {
        Pot storage pot = ORC_POT(msg.sender, signer);
        pot.unlock_warned_ = ORC_WRN(ORC_DAY, warned);
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
            do lottery.recipients_[recipients[--i]] = value;
            while (i != 0);
        }

        emit Bound(msg.sender);
    }


    struct Track {
        uint256 until_;
    }

    mapping(address => mapping(bytes32 => Track)) private tracks_;

    function save(uint256 count, bytes32 seed) external {
        mapping(bytes32 => Track) storage tracks = tracks_[msg.sender];
        seed = ORC_SHA(seed, msg.sender);
        for (;;) {
            tracks[seed].until_ = 1;
            if (count-- == 0)
                break;
            seed = ORC_SHA(seed);
        }
    }

    #define ORC_DEL(d) { \
        Track storage track = tracks[d]; \
        if (track.until_ <= block.timestamp) \
            delete track.until_; \
    }


    /*struct Packed {
        uint63 expire;
        uint32 salt;
        address funder;
        uint1 v;
    }*/

    struct Ticket {
        uint256 random;
        uint256 values;
        uint256 packed;
        bytes32 r; bytes32 s;
    }

    function claim(
        mapping(bytes32 => Track) storage tracks,
        uint256 destination,
        Ticket calldata ticket
        ORC_PRM()
    ) private returns (uint256) {
        uint256 expire = ticket.packed >> 193;
        if (expire <= block.timestamp)
            return 0;

        bytes32 digest; assembly { digest := chainid() } digest = keccak256(abi.encode(
            ORC_SHA(ORC_SHA(uint128(ticket.random)), uint32(ticket.packed >> 161), destination), ticket.random >> 128,
            ticket.values, ticket.packed & ~uint256(1) ORC_ARG, this, digest));
        address signer = ecrecover(digest, uint8((ticket.packed & 1) + 27), ticket.r, ticket.s);

        if ((ticket.values >> 128) < uint128(uint256(ORC_SHA(ticket.random))))
            return 0;
        uint256 amount = uint128(ticket.values);

        address funder = address(ticket.packed >> 1);
        Lottery storage lottery = lotteries_[funder];
        if (lottery.bound_ - 1 < block.timestamp)
            if (lottery.recipients_[address(destination)] <= block.timestamp)
                return 0;
    {
        Track storage track = tracks[bytes32(uint256(signer)) ^ digest];
        if (track.until_ != 0)
            return 0;
        track.until_ = expire;
    }
        Pot storage pot = lottery.pots_[signer]ORC_ARR;
        uint256 cache = pot.escrow_amount_;

        if (uint128(cache) >= amount) {
            emit Update(funder, signer ORC_ARG);
            pot.escrow_amount_ = cache - amount;
            return amount;
        } else {
            emit Delete(funder, signer ORC_ARG);
            pot.escrow_amount_ = 0;
            return uint128(cache);
        }
    }

    #define ORC_GRB \
        address payable recipient = address(destination); \
        mapping(bytes32 => Track) storage tracks = tracks_[recipient];

    #define ORC_DST(amount) \
        if (destination >> 160 == 0) \
            ORC_SND(recipient, amount) \
        else \
            ORC_GFT(recipient, recipient, amount)

    function claimN(bytes32[] calldata refunds, uint256 destination, Ticket[] calldata tickets ORC_PRM()) external {
        ORC_GRB

        uint256 segment; assembly { segment := mload(0x40) }

        uint256 amount = 0;
        for (uint256 i = tickets.length; i != 0; ) {
            amount += claim(tracks, destination, tickets[--i] ORC_ARG);
            assembly { mstore(0x40, segment) }
        }
        ORC_DST(amount)

        for (uint256 i = refunds.length; i != 0; )
            ORC_DEL(refunds[--i])
    }

    function claim1(bytes32 refund, uint256 destination, Ticket calldata ticket ORC_PRM()) external {
        ORC_GRB

        uint256 amount = claim(tracks, destination, ticket ORC_ARG);
        ORC_DST(amount)

        if (refund != 0)
            ORC_DEL(refund)
    }
}
