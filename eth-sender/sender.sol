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

contract OrchidSender {
    address owner_;

    constructor(address owner) {
        owner_ = owner;
    }

    struct Send {
        address recipient;
        uint256 amount;
    }

    function sendv(address token, Send[] calldata sends) external {
        require(owner_ == msg.sender);
        for (uint i = sends.length; i != 0; ) {
            Send calldata send = sends[--i];
            (bool _s, bytes memory _d) = address(token).call(
                abi.encodeWithSignature("transfer(address,uint256)", send.recipient, send.amount));
            require(_s && (_d.length == 0 || abi.decode(_d, (bool))));
        }
    }
}
