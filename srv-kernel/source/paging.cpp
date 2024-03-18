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


// this code runs in lower memory
// on x86_64, this code is 32-bit
// little-endian is our friend ;P

#include "paging.hpp"

__attribute__((__format__ (__printf__, 1, 2)))
extern "C" size_t printf(const char *format, ...);

// NOLINTBEGIN(performance-no-int-to-ptr)
namespace orc {

#if defined(__i386__)
__attribute__((__regcall__))
#endif
extern "C" void setup(Table tables[]) {
#if 0
#elif defined(__aarch64__)
// arm separates low/high tables
static constexpr size_t table_(4);
#elif defined(__i386__)
// x86 has a unified low/high table
static constexpr size_t table_(3);
#else
#error
#endif

    tables[0][0] = BofP(0x0);
    tables[0][1] = BofP(gigapage_);
    tables[1][511] = BofP(boundary_);

    tables[2][0] = TofP(PofL(tables[0]));
    tables[table_-1][511] = TofP(PofL(tables[1]));

#if defined(__i386__)
    // tables[3] is the global descriptor table
    // https://en.wikipedia.org/wiki/Segment_descriptor
    // while limit is often all-f's, it is ignored
    // #f## = (G DB _ A) f (P DPL < S) (Type)
    //             0x--#-##----------;
    tables[3][1] = 0x00Af9B000000ffff; //CS0
    tables[3][2] = 0x00Cf93000000ffff; //SS0
    tables[3][3] = 0x00CfFB000000ffff; //323
    tables[3][4] = 0x00CfF3000000ffff; //SS3
    tables[3][5] = 0x00AfFB000000ffff; //CS3
    // arch/x86/boot/compressed/head_64.S
    // arch/x86/realmode/rm/trampoline_64.S
    // arch/x86/include/asm/segment.h
#if 0
    .quad   0x0080890000000000      /* TS descriptor */
    .quad   0x0000000000000000      /* TS continued */

    8 00 0 0 8b 079000 4087 TSS
    9 00 0 0 00 00ffff fe00 ^

    A 0 LDT
    B 0 ^

    C 0 TLS_MIN
    D 0
    E 0 TLS_MAX

    F 00 4 0 f5 000000 0002 CPUNODE
#endif
#endif
}

}
// NOLINTEND(performance-no-int-to-ptr)
