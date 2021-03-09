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


    function from_(IERC20 token, uint256 amount) private {
        require(token != IERC20(0));
        (bool success, bytes memory result) = address(token).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, this, amount));
        require(success && abi.decode(result, (bool)));
    }

    function send_(address sender, IERC20 token, uint256 retrieve) private {
        if (retrieve != 0) {
            (bool success, bytes memory result) = address(token).call(
                abi.encodeWithSignature("transfer(address,uint256)", sender, retrieve));
            require(success && (result.length == 0 || abi.decode(result, (bool))));
        }
    }

    function gift(IERC20 token, uint256 amount, address funder, address signer, uint256 escrow) external {
        from_(token, amount);
        gift_(msg.sender, funder, token, amount, signer, escrow);
    }

    function edit(IERC20 token, uint256 amount, address signer, int256 adjust, int256 lock, uint256 retrieve) external {
        from_(token, amount);
        edit_(msg.sender, token, amount, signer, adjust, lock, retrieve);
        send_(msg.sender, token, retrieve);
    }


    function tokenFallback(address sender, uint256 amount, bytes calldata data) public {
        IERC20 token = IERC20(msg.sender);

        require(data.length >= 4);
        bytes4 selector; assembly { selector := calldataload(data.offset) }

        if (false) {
        } else if (selector == bytes4(keccak256("edit(address,int256,int256,uint256)"))) {
            address signer; int256 adjust; int256 lock; uint256 retrieve;
            (signer, adjust, lock, retrieve) = abi.decode(data[4:],
                (address, int256, int256, uint256));
            edit_(sender, token, amount, signer, adjust, lock, retrieve);
            send_(msg.sender, token, retrieve);
        } else if (selector == bytes4(keccak256("gift(address,address,uint256)"))) {
            address funder; address signer; uint256 escrow;
            (funder, signer, escrow) = abi.decode(data[4:],
                (address, address, uint256));
            gift_(sender, funder, token, amount, signer, escrow);
        } else require(false);
    }

    function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external returns (bool) {
        tokenFallback(sender, amount, data);
        return true;
    }


    function gift(address funder, address signer, uint256 escrow) external payable {
        gift_(msg.sender, funder, IERC20(0), msg.value, signer, escrow);
    }

    function edit(address signer, int256 adjust, int256 lock, uint256 retrieve) external payable {
        address funder = msg.sender;
        edit_(funder, IERC20(0), msg.value, signer, adjust, lock, retrieve);

        if (retrieve != 0) {
            (bool success,) = funder.call{value: retrieve}("");
            require(success);
        }
    }


    function gift_(address sender, address funder, IERC20 token, uint256 amount, address signer, uint256 escrow) private {
        Pot storage pot = lotteries_[funder].pots_[signer][token];

        uint256 cache = pot.escrow_amount_;
        if (cache == 0)
            emit Create(token, funder, signer);

        if (escrow != 0) {
            require(escrow <= amount);
            amount -= escrow;
            require((cache >> 128) + escrow < 1 << 128);
        }

        require(uint128(cache) + amount < 1 << 128);
        cache += escrow << 128 | amount;
        pot.escrow_amount_ = cache;

        emit Update(keccak256(abi.encodePacked(token, funder, signer)), cache, sender);
    }

    function edit_(address funder, IERC20 token, uint256 amount, address signer, int256 adjust, int256 lock, uint256 retrieve) private {
        Pot storage pot = lotteries_[funder].pots_[signer][token];

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
            require(warned < 1 << 128);
        }

        if (retrieve != 0) {
            require(retrieve <= amount);
            amount -= retrieve;
        }

        if (unlock != 0) {
            uint256 cache = (warned == 0 ? 0 : unlock << 128 | warned);
            pot.unlock_warned_ = cache;
            emit Delete(keccak256(abi.encodePacked(token, funder, signer)), cache);
        }
    } {
        require(amount < 1 << 128);
        require(escrow < 1 << 128);

        uint256 cache = escrow << 128 | amount;
        if (cache != backup) {
            pot.escrow_amount_ = cache;
            emit Update(keccak256(abi.encodePacked(token, funder, signer)), cache, funder);
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
        for (seed = keccak256(abi.encodePacked(
            keccak256(abi.encodePacked(seed, msg.sender))
        , address(0)));; seed = keccak256(abi.encodePacked(seed))) {
            tracks_[seed].packed = uint256(msg.sender);
            if (count-- == 0)
                break;
        }
    }

    function spend_(bytes32 refund) private {
        Track storage track = tracks_[refund];
        uint256 packed = track.packed;
        if (packed >> 160 <= block.timestamp)
            if (address(packed) == msg.sender)
                delete track.packed;
    }


    /*struct Ticket {
        uint256 reveal;

        uint64 issued;
        uint64 nonce;
        uint128 amount;

        uint31 expire;
        uint64 ratio;
        address funder;
        uint1 v;

        bytes32 r;
        bytes32 s;
    }*/

    struct Ticket {
        bytes32 reveal;
        uint256 packed0;
        uint256 packed1;
        bytes32 r;
        bytes32 s;
    }

    function claim_(IERC20 token, address recipient, Ticket calldata ticket) private returns (uint256) {
        uint256 expire = (ticket.packed0 >> 192) + (ticket.packed1 >> 225);
        if (expire <= block.timestamp)
            return 0;

        bytes32 digest; assembly { digest := chainid() }
        digest = keccak256(abi.encodePacked(
            byte(0x19), byte(0x00), this, digest, token,
            keccak256(abi.encodePacked(ticket.reveal, recipient)),
            ticket.packed0, ticket.packed1 >> 1));

        address signer = ecrecover(digest, uint8((ticket.packed1 & 1) + 27), ticket.r, ticket.s);

        if (uint64(ticket.packed1 >> 161) < uint64(uint256(keccak256(abi.encodePacked(ticket.reveal, uint128(ticket.packed0 >> 128))))))
            return 0;
        uint256 amount = uint128(ticket.packed0);

        address funder = address(ticket.packed1 >> 1);
        Lottery storage lottery = lotteries_[funder];
        if (lottery.bound_ - 1 < block.timestamp)
            if (lottery.recipients_[recipient] <= block.timestamp)
                return 0;
    {
        Track storage track = tracks_[keccak256(abi.encodePacked(digest, signer))];
        if (track.packed != 0)
            return 0;
        track.packed = expire << 160 | uint256(msg.sender);
    }
        Pot storage pot = lottery.pots_[signer][token];
        uint256 cache = pot.escrow_amount_;

        if (uint128(cache) >= amount)
            cache -= amount;
        else {
            amount = uint128(cache);
            cache = 0;
        }

        pot.escrow_amount_ = cache;
        emit Update(keccak256(abi.encodePacked(token, funder, signer)), cache, address(0));
        return amount;
    }


    function claim(IERC20 token, address recipient, Ticket[] calldata tickets, bytes32[] calldata refunds) external {
        if (recipient == address(0))
            recipient = msg.sender;

        for (uint256 i = refunds.length; i != 0; )
            spend_(refunds[--i]);

        uint256 segment; assembly { segment := mload(0x40) }

        uint256 amount = 0;
        for (uint256 i = tickets.length; i != 0; ) {
            amount += claim_(token, recipient, tickets[--i]);
            assembly { mstore(0x40, segment) }
        }

        if (amount != 0)
            gift_(recipient, recipient, token, amount, recipient, 0);
    }
}
