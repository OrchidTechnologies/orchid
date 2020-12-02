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


object "OrchidRecipient" {
    code {
        datacopy(0, dataoffset("code"), datasize("code"))
        return(0, datasize("code"))
    }

    object "code" {
        code {
            calldatacopy(0, 0, calldatasize())
            pop(call(gas(), 0x4575f41308EC1483f3d399aa9a2826d74Da13Deb, 0, 0, calldatasize(), 0, 0))
        }
    }
}
