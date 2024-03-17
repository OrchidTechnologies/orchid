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


#ifndef ORCHID_PAGING_HPP
#define ORCHID_PAGING_HPP

#include <cstdint>
#include <cstdlib>

// NOLINTBEGIN(performance-no-int-to-ptr)
namespace orc {

static constexpr size_t addrbits_(48);
static constexpr size_t pagebits_(12);

typedef uint64_t Entry;
static constexpr size_t wordbits_(3);
static_assert(1 << wordbits_ == sizeof(Entry));

static constexpr size_t indxbits_(pagebits_ - wordbits_);
typedef Entry Table[1 << indxbits_];

static constexpr size_t kilopage_(1 << (0 * indxbits_ + pagebits_));
static constexpr size_t megapage_(1 << (1 * indxbits_ + pagebits_));
static constexpr size_t gigapage_(1 << (2 * indxbits_ + pagebits_));

#if defined(__aarch64__)
static constexpr size_t boundary_(gigapage_);
#else
static constexpr size_t boundary_(0);
#endif

inline uintptr_t PofL(const void *address) { return reinterpret_cast<uintptr_t>(address); }

inline uintptr_t PofK(const void *address) { return reinterpret_cast<uintptr_t>(address) + gigapage_ + boundary_; }

template <typename Type_ = void>
inline Type_ *KofP(uintptr_t physical) { return reinterpret_cast<Type_ *>(physical - boundary_ - gigapage_); }

#define MASK(bits) ((Entry(1) << bits) - 1)

static constexpr Entry nextmask_(MASK(addrbits_) & ~MASK(pagebits_));
static constexpr Entry restmask_(~(nextmask_ | 0x1));
static constexpr uintptr_t holdpage_(0);

// T: Table
// B: Block

// E: Entry
// R: Rest
// F: Flags

// P: Physical
// K: Kernel
// L: Low

static constexpr bool isE(Entry entry) { return (entry & 0x1) != 0; }
static constexpr uintptr_t PofE(uintptr_t entry) { return entry & nextmask_; }

#if 0
#elif defined(__aarch64__)
// https://armv8-ref.codingbelief.com/en/chapter_d4/d43_vmsav8-64_translation_table_format_descriptors.html
// https://medium.com/@om.nara/arm64-normal-memory-attributes-6086012fa0e3

static constexpr Entry TofP(uintptr_t physical) { return physical | uintptr_t(0x003); }
static constexpr Entry BofP(uintptr_t physical) { return physical | uintptr_t(0x601); }

static constexpr Entry RofF(bool writable, bool executable) {
    Entry value(1ull << 53 | 0x642);
    if (!writable) value |= 1ull << 7;
    if (!executable) value |= 1ull << 54;
    return value;
}
#elif defined(__x86_64__) || defined(__i386__)
// https://wiki.osdev.org/Paging

static constexpr Entry TofP(uintptr_t physical) { return physical | uintptr_t(0x07); }
static constexpr Entry BofP(uintptr_t physical) { return physical | uintptr_t(0x83); }

static constexpr Entry RofF(bool writable, bool executable) {
    Entry value(1ull << 2);
    if (writable) value |= 1ull << 1;
    if (!executable) value |= 1ull << 63;
    return value;
}
#else
#error
#endif

}
// NOLINTEND(performance-no-int-to-ptr)

#endif//ORCHID_PAGING_HPP
