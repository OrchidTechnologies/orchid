/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2020  The Orchid Authors
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


object "Layer3" {
    code {
        let size := datasize("code")
        codecopy(0, dataoffset("code"), size)
        return(0, size)
    }

    object "code" {
        code {
            switch shr(224, calldataload(0))

            case 0x0011e333 { // commit(uint256,uint8,bytes32,bytes32)
                calldatacopy(0x00, 0x04, 0x80)
                if iszero(staticcall(gas(), 1, 0x00, 0x80, 0x00, 0x20)) { revert(0, 0) }
                let slot := mload(0x00)
                /*mstore(0x20, 0)
                let slot := keccak256(0x00, 0x40)*/
                if not(iszero(sload(slot))) { revert(0, 0) }
                sstore(slot, calldataload(0x04))
            }

            case 0xf340fa01 { // deposit(address)
            }

            default { revert(0, 0) }
        }
    }
}
