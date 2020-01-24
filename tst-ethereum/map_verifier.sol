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


pragma solidity 0.5.13;

import "dir-ethereum/curator.sol";

// note: this interface defines book as a view function instead of pure
interface OrchidVerifier {
    function book(bytes calldata shared, address target, bytes calldata receipt) external view;
}


contract OrchidListVerifier is OrchidVerifier {

    OrchidList internal curator_;

    constructor(OrchidList curator) public {
        curator_ = curator;
    }

    function book(bytes calldata, address target, bytes calldata receipt) external view {
        require(curator_.good(target, receipt) != uint128(0));
    }
    
}
