/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2020  The Orchid Authors
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
#define ORC_SHA(a, ...) keccak256(abi.encode(a,## __VA_ARGS__))

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


    event Warn(address indexed funder, address indexed signer ORC_PRM(indexed), uint256 unlock_warned);
    event Claim(address indexed funder, address indexed signer ORC_PRM(indexed), uint256 escrow_amount);

    event Create(address indexed funder, address indexed signer ORC_PRM(indexed), uint256 escrow_amount);
    event Update(address indexed funder, address indexed signer ORC_PRM(indexed), uint256 escrow_amount);

    #define ORC_EVT(f, s, v) { \
        if (create) \
            emit Create(f, s ORC_ARG, v); \
        else \
            emit Update(f, s ORC_ARG, v); \
    }


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

    #define ORC_ADD(f, s, a) { \
        Pot storage pot = ORC_POT(f, s); \
        uint256 cache = pot.escrow_amount_; \
        require(uint128(cache) + a >> 128 == 0); \
        bool create = cache == 0; \
        cache += a; \
        pot.escrow_amount_ = cache; \
        ORC_EVT(f, s, cache) \
    }


#if defined(ORC_SYM)
    #define ORC_FRM(a) { \
        (bool _s, bytes memory _d) = address(ORC_TOK).call( \
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), a)); \
        require(_s && abi.decode(_d, (bool))); \
    }

    function gift(address funder, address signer ORC_PRM(), uint256 amount) external {
        ORC_FRM(amount)
        ORC_ADD(funder, signer, amount)
    }

    function move(address signer ORC_PRM(), uint256 amount, uint256 adjust_retrieve) external {
        ORC_FRM(amount)
        move_(msg.sender, signer ORC_ARG, amount, adjust_retrieve);
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
            ORC_ADD(sender, sender, amount)
        else {
            // XXX: this should be calldataload(data.offset), maybe with an add or a shr in there
            bytes memory copy = data; bytes4 selector; assembly { selector := mload(add(copy, 32)) }
            if (false) {
            } else if (selector == Move_) {
                address signer; uint256 adjust_retrieve;
                (signer, adjust_retrieve) = abi.decode(data[4:], (address, uint256));
                move_(sender, signer ORC_ARG, amount, adjust_retrieve);
            } else if (selector == Gift_) {
                address funder; address signer;
                (funder, signer) = abi.decode(data[4:], (address, address));
                ORC_ADD(funder, signer, amount)
            } else require(false);
        }
    }

    function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external returns (bool) {
        tokenFallback(sender, amount, data);
        return true;
    }

    function move_(address funder, address signer ORC_PRM(), uint256 amount, uint256 adjust_retrieve) private {
#else
    receive() external payable {
        ORC_ADD(msg.sender, msg.sender, msg.value)
    }

    function gift(address funder, address signer) external payable {
        ORC_ADD(funder, signer, msg.value)
    }

    function move(address signer, uint256 adjust_retrieve) external payable {
        address payable funder = msg.sender;
        uint256 amount = msg.value;
#endif
        Pot storage pot = ORC_POT(funder, signer);

        uint256 escrow = pot.escrow_amount_;
        bool create = escrow == 0;
        amount += uint128(escrow);
        escrow = escrow >> 128;

        int256 adjust = int256(adjust_retrieve) >> 128;
        uint256 retrieve = uint128(adjust_retrieve);

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
            emit Warn(msg.sender, signer ORC_ARG, pot.unlock_warned_);
        } else if (adjust != 0) {
            uint256 transfer = uint256(adjust);
            require(transfer <= amount);
            amount -= transfer;
            escrow += transfer;
        }

        if (retrieve != 0) {
            require(retrieve <= amount);
            amount -= retrieve;
        }

        require(amount < 1 << 128);
        require(escrow < 1 << 128);
        uint256 cache = escrow << 128 | amount;
        pot.escrow_amount_ = cache;

        ORC_EVT(funder, signer, cache)

        if (retrieve != 0)
            ORC_SND(funder, retrieve)
    }

    function warn(address signer ORC_PRM(), uint128 warned) external {
        Pot storage pot = ORC_POT(msg.sender, signer);
        pot.unlock_warned_ = ORC_WRN(ORC_DAY, warned);
        emit Warn(msg.sender, signer ORC_ARG, pot.unlock_warned_);
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


    /*struct Track {
        uint96 expire;
        address owner;
    }*/

    struct Track {
        uint256 packed;
    }

    mapping(bytes32 => Track) private tracks_;

    function save(uint256 count, bytes32 seed) external {
        for (seed = ORC_SHA(seed, msg.sender);; seed = ORC_SHA(seed)) {
            tracks_[seed].packed = uint256(msg.sender);
            if (count-- == 0)
                break;
        }
    }

    #define ORC_DEL(d) { \
        Track storage track = tracks_[d]; \
        uint256 packed = track.packed; \
        if (packed >> 160 <= block.timestamp) \
            if (address(packed) == msg.sender) \
                delete track.packed; \
    }


    /*struct Ticket {
        uint128 reveal;
        uint128 nonce;

        uint64 issued;
        uint64 ratio;
        uint128 amount;

        uint63 expire;
        address funder;
        uint32 salt;
        uint1 v;

        bytes32 r;
        bytes32 s;
    }*/

    struct Ticket {
        uint256 packed0;
        uint256 packed1;
        uint256 packed2;
        bytes32 r;
        bytes32 s;
    }

    function claim_(
        uint256 destination,
        Ticket calldata ticket
        ORC_PRM()
    ) private returns (uint256) {
        uint256 issued = (ticket.packed1 >> 192);
        uint256 expire = issued + (ticket.packed2 >> 193);
        if (expire <= block.timestamp)
            return 0;

        bytes32 digest; assembly { digest := chainid() } digest = ORC_SHA(
            ORC_SHA(ORC_SHA(ticket.packed0 >> 128, destination), uint32(ticket.packed2 >> 1)),
            uint128(ticket.packed0), ticket.packed1, ticket.packed2 & ~uint256(0x1ffffffff) ORC_ARG, this, digest);
        address signer = ecrecover(digest, uint8((ticket.packed2 & 1) + 27), ticket.r, ticket.s);

        if (uint64(ticket.packed1 >> 128) < uint64(uint256(ORC_SHA(ticket.packed0, issued))))
            return 0;
        uint256 amount = uint128(ticket.packed1);

        address funder = address(ticket.packed2 >> 33);
        Lottery storage lottery = lotteries_[funder];
        if (lottery.bound_ - 1 < block.timestamp)
            if (lottery.recipients_[address(destination)] <= block.timestamp)
                return 0;
    {
        Track storage track = tracks_[bytes32(uint256(signer)) ^ digest];
        if (track.packed != 0)
            return 0;
        track.packed = expire << 160 | uint256(msg.sender);
    }
        Pot storage pot = lottery.pots_[signer]ORC_ARR;
        uint256 cache = pot.escrow_amount_;

        if (uint128(cache) >= amount) {
            pot.escrow_amount_ = cache - amount;
            emit Claim(funder, signer ORC_ARG, pot.escrow_amount_);
            return amount;
        } else {
            pot.escrow_amount_ = 0;
            emit Claim(funder, signer ORC_ARG, 0);
            return uint128(cache);
        }
    }


    /*struct Destination {
        uint1 direct;
        uint95 pepper;
        address recipient;
    }*/

    #define ORC_CLM \
        address payable recipient = address(destination); \
        if (recipient == address(0)) \
            destination |= uint256(recipient = msg.sender);

    #define ORC_DST \
        if (amount == 0) {} \
        else if (destination >> 255 == 0) \
            ORC_SND(recipient, amount) \
        else \
            ORC_ADD(recipient, recipient, amount)

    function claimN(bytes32[] calldata refunds, uint256 destination, Ticket[] calldata tickets ORC_PRM()) external {
        ORC_CLM

        for (uint256 i = refunds.length; i != 0; )
            ORC_DEL(refunds[--i])

        uint256 segment; assembly { segment := mload(0x40) }

        uint256 amount = 0;
        for (uint256 i = tickets.length; i != 0; ) {
            amount += claim_(destination, tickets[--i] ORC_ARG);
            assembly { mstore(0x40, segment) }
        }
        ORC_DST
    }

    function claim1(bytes32 refund, uint256 destination, Ticket calldata ticket ORC_PRM()) external {
        ORC_CLM

        if (refund != 0)
            ORC_DEL(refund)

        uint256 amount = claim_(destination, ticket ORC_ARG);
        ORC_DST
    }
}
