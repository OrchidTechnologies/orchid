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

import "../lot-ethereum/include.sol";

contract OrchidLocked is OrchidSeller, OrchidVerifier {
    mapping (bytes => mapping(address => bytes)) receipts_;

    function book(bytes memory shared, address target, bytes memory receipt) public pure {
        require(receipt.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(receipt, 32))
            s := mload(add(receipt, 64))
            v := and(mload(add(receipt, 65)), 255)
        }

        bytes32 message = keccak256(abi.encodePacked(target, shared));
        address signer = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message)), v, r, s);
        require(signer == address(0xff0fce1d));
    }

    function list(bytes calldata shared, address target, bytes calldata receipt) external {
        book(shared, target, receipt);
        receipts_[shared][target] = receipt;
    }

    function ring(bytes calldata shared, address target) external view returns (bytes memory) {
        bytes storage receipt = receipts_[shared][target];
        require(receipt.length != 0);
        return receipt;
    }
}
