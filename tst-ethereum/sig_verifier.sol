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


interface OrchidVerifier {
    function book(bytes calldata shared, address target, bytes calldata receipt) external pure;
}

contract SigVerifier is OrchidVerifier {
    constructor() public {
    }

    function book(bytes calldata shared_, address target, bytes calldata receipt_) external pure {
    
        bytes memory shared = shared_;
        bytes memory receipt = receipt_;

        bytes32 ticket = keccak256(abi.encode(target));

        bytes32 r;
        bytes32 s;
        uint8 v;
        address o;
        assembly {
            r := mload(add(receipt, 32))
            s := mload(add(receipt, 64))
            v := mload(add(receipt, 96))
            o := mload(add(shared,  32))
        }
        address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", ticket)), v, r, s);
        require(signer == o);
    }

}

