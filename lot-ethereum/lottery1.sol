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


pragma solidity 0.7.6;
pragma abicoder v2;

#define ORC_256 keccak256)(abi.encodePacked
#define ORC_191 byte(0x19), byte(0x00), this
#define ORC_128(v) require((v) < 1 << 128)

interface IERC20 {}

contract OrchidLottery1 {
    uint64 private immutable day_;

    constructor(uint64 day) {
        day_ = day;
    }


    struct Pot {
        uint256 escrow_amount_;
        uint256 unlock_warned_;
    }

    event Create(IERC20 indexed token, address indexed funder, address indexed signer);
    event Update(bytes32 indexed account, uint256 escrow_amount, address sender);
    event Delete(bytes32 indexed account, uint256 unlock_warned);


    struct Lottery {
        mapping(address => mapping(IERC20 => Pot)) pots_;
        uint256 bound_;
        mapping(address => uint256) recipients_;
    }

    mapping(address => Lottery) private lotteries_;

    function read(IERC20 token, address funder, address signer, address recipient) external view returns (uint256, uint256, uint256) {
        Lottery storage lottery = lotteries_[funder];
        Pot storage pot = lottery.pots_[signer][token];
        return (pot.escrow_amount_, pot.unlock_warned_, lottery.bound_ << 128 | lottery.recipients_[recipient]);
    }

    #define ORC_POT(f, s) \
        lotteries_[f].pots_[s][token]

    #define ORC_ADD(sender, funder, signer, escrow) { \
        Pot storage pot = ORC_POT(funder, signer); \
        uint256 cache = pot.escrow_amount_; \
        if (cache == 0) \
            emit Create(token, funder, signer); \
        if (escrow != 0) { \
            require(escrow <= amount); \
            amount -= escrow; \
            ORC_128((cache >> 128) + escrow); \
        } \
        ORC_128(uint128(cache) + amount); \
        cache += escrow << 128 | amount; \
        pot.escrow_amount_ = cache; \
        emit Update((ORC_256(token, funder, signer)), cache, sender); \
    }


    #define ORC_FRM(a) { \
        require(token != IERC20(0)); \
        (bool _s, bytes memory _d) = address(token).call( \
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), a)); \
        require(_s && abi.decode(_d, (bool))); \
    }

    #define ORC_TRN(funder) if (retrieve != 0) { \
        (bool success, bytes memory result) = address(token).call( \
            abi.encodeWithSignature("transfer(address,uint256)", funder, retrieve)); \
        require(success && (result.length == 0 || abi.decode(result, (bool)))); \
    }

    function gift(IERC20 token, uint256 amount, address funder, address signer, uint256 escrow) external {
        ORC_FRM(amount)
        ORC_ADD(msg.sender, funder, signer, escrow)
    }

    function move(IERC20 token, uint256 amount, address signer, int256 adjust, int256 lock, uint256 retrieve) external {
        ORC_FRM(amount)
        move_(msg.sender, token, amount, signer, adjust, lock, retrieve);
        ORC_TRN(msg.sender)
    }


    function tokenFallback(address sender, uint256 amount, bytes calldata data) public {
        IERC20 token = IERC20(msg.sender);

        require(data.length >= 4);
        bytes4 selector; assembly { selector := calldataload(data.offset) }

        if (false) {
        } else if (selector == bytes4(keccak256("move(address,int256,int256,uint256)"))) {
            address signer; int256 adjust; int256 lock; uint256 retrieve;
            (signer, adjust, lock, retrieve) = abi.decode(data[4:],
                (address, int256, int256, uint256));
            move_(sender, token, amount, signer, adjust, lock, retrieve);
            ORC_TRN(sender)
        } else if (selector == bytes4(keccak256("gift(address,address,uint256)"))) {
            address funder; address signer; uint256 escrow;
            (funder, signer, escrow) = abi.decode(data[4:],
                (address, address, uint256));
            ORC_ADD(sender, funder, signer, escrow)
        } else require(false);
    }

    function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external returns (bool) {
        tokenFallback(sender, amount, data);
        return true;
    }


    #define ORC_HRD() \
        IERC20 token = IERC20(0); \
        uint256 amount = msg.value;

    function gift(address funder, address signer, uint256 escrow) external payable {
        ORC_HRD()
        ORC_ADD(msg.sender, funder, signer, escrow)
    }

    function move(address signer, int256 adjust, int256 lock, uint256 retrieve) external payable {
        address funder = msg.sender;
        ORC_HRD()
        move_(funder, token, amount, signer, adjust, lock, retrieve);

        if (retrieve != 0) {
            (bool success,) = funder.call{value: retrieve}("");
            require(success);
        }
    }


    function move_(address funder, IERC20 token, uint256 amount, address signer, int256 adjust, int256 lock, uint256 retrieve) private {
        Pot storage pot = ORC_POT(funder, signer);

        uint256 backup;
        uint256 escrow;

        if (adjust != 0 || amount != retrieve) {
            backup = pot.escrow_amount_;
            if (backup == 0)
                emit Create(token, funder, signer);
            escrow = backup >> 128;
            amount += uint128(backup);
        } else {
            backup = 0;
            escrow = 0;
        }
    {
        uint256 warned;
        uint256 unlock;

        if (adjust < 0 || lock != 0) {
            warned = pot.unlock_warned_;
            unlock = warned >> 128;
            warned = uint128(warned);
        }

        if (adjust < 0) {
            require(unlock - 1 < block.timestamp);

            uint256 recover = uint256(-adjust);
            require(int256(recover) != adjust);

            require(recover <= escrow);
            amount += recover;
            escrow -= recover;

            require(recover <= warned);
            warned -= recover;
        } else if (adjust != 0) {
            uint256 transfer = uint256(adjust);

            require(transfer <= amount);
            amount -= transfer;
            escrow += transfer;
        }

        if (lock < 0) {
            uint256 decrease = uint256(-lock);
            require(int256(decrease) != lock);

            require(decrease <= warned);
            warned -= decrease;
        } else if (lock != 0) {
            unlock = block.timestamp + day_;

            warned += uint256(lock);
            require(warned > uint256(lock));
            ORC_128(warned);
        }

        if (retrieve != 0) {
            require(retrieve <= amount);
            amount -= retrieve;
        }

        if (unlock != 0) {
            uint256 cache = (warned == 0 ? 0 : unlock << 128 | warned);
            pot.unlock_warned_ = cache;
            emit Delete((ORC_256(token, funder, signer)), cache);
        }
    } {
        ORC_128(amount);
        ORC_128(escrow);

        uint256 cache = escrow << 128 | amount;
        if (cache != backup) {
            pot.escrow_amount_ = cache;
            emit Update((ORC_256(token, funder, signer)), cache, funder);
        }
    } }


    event Bound(address indexed funder);

    function bind(bool allow, address[] calldata recipients) external {
        Lottery storage lottery = lotteries_[msg.sender];

        uint i = recipients.length;
        if (i == 0)
            lottery.bound_ = allow ? 0 : block.timestamp + day_;
        else {
            uint256 value = allow ? uint256(-1) :
                lottery.bound_ < block.timestamp ? 0 : block.timestamp + day_;
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
        for (seed = (ORC_256(seed, msg.sender));; seed = (ORC_256(seed))) {
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

    function claim_(uint256 destination, Ticket calldata ticket, IERC20 token) private returns (uint256) {
        uint256 issued = (ticket.packed1 >> 192);
        uint256 expire = issued + (ticket.packed2 >> 193);
        if (expire <= block.timestamp)
            return 0;

        bytes32 digest; assembly { digest := chainid() } digest = (ORC_256(ORC_191, digest,
            (ORC_256((ORC_256(uint128(ticket.packed0 >> 128), destination)), uint32(ticket.packed2 >> 1))),
            uint128(ticket.packed0), ticket.packed1, uint224(ticket.packed2 >> 33), token));
        address signer = ecrecover(digest, uint8((ticket.packed2 & 1) + 27), ticket.r, ticket.s);

        if (uint64(ticket.packed1 >> 128) < uint64(uint256((ORC_256(ticket.packed0, issued)))))
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
        Pot storage pot = lottery.pots_[signer][token];
        uint256 cache = pot.escrow_amount_;

        if (uint128(cache) >= amount) {
            cache -= amount;
            pot.escrow_amount_ = cache;
            emit Update((ORC_256(token, funder, signer)), cache, address(0));
            return amount;
        } else {
            pot.escrow_amount_ = 0;
            emit Update((ORC_256(token, funder, signer)), 0, address(0));
            return uint128(cache);
        }
    }


    /*struct Destination {
        uint96 pepper;
        address recipient;
    }*/

    function claim(IERC20 token, uint256 destination, Ticket[] calldata tickets, bytes32[] calldata refunds) external {
        address payable recipient = address(destination);
        if (recipient == address(0))
            destination |= uint256(recipient = msg.sender);

        for (uint256 i = refunds.length; i != 0; )
            ORC_DEL(refunds[--i])

        uint256 segment; assembly { segment := mload(0x40) }

        uint256 amount = 0;
        for (uint256 i = tickets.length; i != 0; ) {
            amount += claim_(destination, tickets[--i], token);
            assembly { mstore(0x40, segment) }
        }

        if (amount != 0)
            ORC_ADD(recipient, recipient, recipient, 0)
    }
}
