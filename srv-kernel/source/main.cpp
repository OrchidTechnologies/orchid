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


#include <cstdlib>

#include <elf.h>

#include "scope.hpp"
#include "worker.hpp"

// NOLINTBEGIN(performance-no-int-to-ptr)
namespace orc {

static const auto control_(reinterpret_cast<volatile uintptr_t *>(0x10000000));

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-noreturn"
__attribute__ ((__noreturn__))
void abort() {
    *control_ = 1;
}
#pragma clang diagnostic pop


void *memcpy(void *dest, const void *src, size_t size) {
    for (size_t i(0); i != size; ++i)
        reinterpret_cast<uint8_t *>(dest)[i] = reinterpret_cast<const uint8_t *>(src)[i];
    return dest;
}

size_t strlen(const char *data) {
    for (size_t size(0);; ++size)
        if (data[size] == '\0')
            return size;
}

// snprintf {{{
static char *itoa_(uintmax_t value, char *data, unsigned int base, bool upper) {
    if (value == 0)
        *--data = '0';
    else while (value != 0) {
        const auto digit(value % base);
        value /= base;
        *--data = char(digit < 10 ? digit + '0' : digit - 10 + (upper ? 'A' : 'a'));
    }

    return data;
}

// NOLINTBEGIN(cppcoreguidelines-pro-type-vararg)
size_t vsnprintf(char *str, size_t max, const char *format, va_list args) {
    auto end(str);
    size_t length(0);

    const auto copy([&](const char *data, size_t size) {
        if (length + size < length) abort();
        length += size;
        if (end != nullptr) {
            if (max < length) abort();
            memcpy(end, data, size);
            end += size;
        }
    });

    #define number(type, base, negate, upper) do { \
        auto value(va_arg(args, type)); \
        bool negative; \
        if (!negate || value >= 0) \
            negative = false; \
        else { \
            negative = true; \
            value = -value; \
            if (value < 0) abort(); \
        } \
        char buf[32]; \
        auto begin(itoa_(value, buf + sizeof(buf), base, upper)); \
        if (negative) *--begin = '-'; \
        copy(begin, buf + sizeof(buf) - begin); \
    } while (false)

    #define integral(stype, utype) \
        case 'd': number(stype, 10, true, false); break; \
        case 'o': number(stype, 8, false, false); break; \
        case 'u': number(stype, 10, false, false); break; \
        case 'x': number(utype, 16, false, false); break; \
        case 'X': number(utype, 16, false, true); break; \
        default: abort();

    for (;;) switch (const auto next = *format++) {
        case '\0':
            if (end != nullptr) {
                if (length == max) abort();
                *end = '\0';
            }
            return length;

        default: copy(&next, 1); break;

        case '%': switch (*format++) {
            integral(int, unsigned)

            case 'z': switch (*format++) {
                integral(ssize_t, size_t)
            } break;

            case 'l': switch (*format++) {
                integral(long, unsigned long)

                case 'l': switch (*format++) {
                    integral(long long, unsigned long long)
                } break;
            } break;

            case 'p':
                copy("0x", 2);
                number(uintptr_t, 16, false, false);
            break;

            case 's': {
                if (const auto value = va_arg(args, const char *))
                    copy(value, strlen(value));
                else
                    copy("(null)", 6);
            } break;
        } break;
    }
}
// NOLINTEND(cppcoreguidelines-pro-type-vararg)

// NOLINTBEGIN(cppcoreguidelines-pro-type-vararg,cert-dcl50-cpp)
size_t snprintf(char *str, size_t size, const char *format, ...) {
    va_list args; va_start(args, format);
    auto value(vsnprintf(str, size, format, args));
    va_end(args);
    return value;
}
// NOLINTEND(cppcoreguidelines-pro-type-vararg,cert-dcl50-cpp)
// }}}

static const size_t kibibyte_(1024);
static const size_t mebibyte_(1024*kibibyte_);
//static const size_t gibibyte_(1024*mebibyte_);

// NOLINTBEGIN(cppcoreguidelines-pro-type-vararg,cert-dcl50-cpp)
__attribute__ ((__format__ (__printf__, 1, 2)))
size_t printf(const char *format, ...) {
    const auto buffer(reinterpret_cast<char *>(mebibyte_));
    va_list args; va_start(args, format);
    auto value(vsnprintf(buffer, mebibyte_, format, args));
    va_end(args);
#ifdef __aarch64__
    __asm__ volatile ("dc civac, %0" : : "r" (buffer) : "memory");
#endif
    *control_ = 2;
    return value;
}
// NOLINTEND(cppcoreguidelines-pro-type-vararg,cert-dcl50-cpp)


template <typename Type_ = void>
Type_ *palloc() {
    return nullptr;
}

void free(void *page) {
}

static const auto PKoffset_(uintptr_t(0x0) - mebibyte_);
uintptr_t PofK(void *address) { return reinterpret_cast<uintptr_t>(address) - PKoffset_; }
void *KofP(uintptr_t physical) { return reinterpret_cast<void *>(physical + PKoffset_); }


static const size_t wordbits_(3);
static_assert(1 << wordbits_ == sizeof(uintptr_t));

static const size_t pagebits_(12);
static const size_t pagesize_(1 << pagebits_);

static const size_t indxbits_(pagebits_ - wordbits_);
typedef uintptr_t Table[1 << indxbits_];

#define MASK(bits) ((uintptr_t(1) << bits) - 1)

#if defined(__aarch64__)

bool Present(uintptr_t entry) { return (entry & MASK(1)) != 0; }
uintptr_t PofE(uintptr_t entry) { return entry & ~MASK(pagebits_); }

#if 0
#elif defined(__aarch64__)
uintptr_t EofP(uintptr_t physical) { return physical | uintptr_t(0x3); }
#else
#error
#endif

template <size_t Level_>
struct Remap { static void _(uintptr_t &entry, uintptr_t address, const auto &code) {
    if constexpr (Level_ != 4) if (!Present(entry)) entry = EofP(PofK(palloc()));
    const auto index((address >> (indxbits_ * (Level_ - 1))) & MASK(indxbits_));
    return Remap<Level_ - 1>::_((*static_cast<Table *>(KofP(PofE(entry))))[index], address, code);
} };

template <>
struct Remap<0> { static void _(uintptr_t &entry, uintptr_t address, const auto &code) {
    return code(entry, address << pagebits_);
} };

void remap(uintptr_t base, size_t size, const auto &code) {
    if ((base & MASK(pagebits_)) != 0) abort();
    if ((size & MASK(pagebits_)) != 0) abort();

#if 0
#elif defined(__aarch64__)
    uintptr_t table;
    if (intptr_t(base) >= 0)
        __asm__ volatile ("msr ttbr0_el1, %0" : "=r" (table));
    else
        __asm__ volatile ("msr ttbr1_el1, %0" : "=r" (table));
#else
#error
#endif

    Remap<4>::_(table, base >> pagebits_, [&](uintptr_t &entry, uintptr_t page) {
        if (Present(entry))
            free(KofP(PofE(entry)));
        code(entry, page);
    });
}

void mmap(uintptr_t base, size_t size) {
    remap(base, size, [](uintptr_t &entry, uintptr_t page) { entry = EofP(PofK(palloc())); });
}

void munmap(uintptr_t base, size_t size) {
    remap(base, size, [](uintptr_t &entry, uintptr_t page) { entry = 0; });
}

#endif

extern "C" void _start() {
    (void) pagesize_;

#if 0
#elif defined(__aarch64__)
    uint64_t *table(nullptr);
    __asm__ volatile ("msr ttbr0_el1, %0" : "=r" (table));

    table = reinterpret_cast<uint64_t *>(mebibyte_ + pagesize_);

    __asm__ volatile (
        "msr ttbr0_el1, %0\n"
        "isb\n"
        "mrs x0, sctlr_el1\n"
        "orr x0, x0, #1\n"
        "msr sctlr_el1, x0\n"
        "isb\n"
    : : "r" (table) : "memory", "x0");

    const auto &header(*reinterpret_cast<const Elf64_Ehdr *>(worker_data));
    const uint64_t entry(header.e_entry);
    const auto commands(reinterpret_cast<const Elf64_Phdr *>(worker_data + header.e_phoff));
    for (size_t i(0); i != header.e_phnum; ++i)
        if (const auto &command(commands[i]); command.p_type == PT_LOAD)
            // NOLINTNEXTLINE(cppcoreguidelines-pro-type-vararg)
            printf("load %lx %p %lx\n", command.p_paddr, worker_data + command.p_offset, command.p_filesz);
            //memcpy(memory + command.p_paddr, worker_data + command.p_offset, command.p_filesz);
    (void) entry;
#endif

    abort();
}

}
// NOLINTEND(performance-no-int-to-ptr)
