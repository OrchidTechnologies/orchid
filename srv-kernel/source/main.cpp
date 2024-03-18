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


#ifdef __x86_64__
#include <asm/prctl.h>
#endif
#include <asm/unistd.h>

#include <linux/auxvec.h>

#include <sys/mman.h>
#include <sys/resource.h>

#include <elf.h>

#include <cerrno>
#include <cstdarg>

#include "paging.hpp"

namespace orc {

// assembly helpers {{{
#if 0
#elif defined(__aarch64__)
#define Clear(code) \
    __asm__ volatile ("dc cvac, %0" : : "r" (code) : "memory")
#elif defined(__x86_64__) || defined(__i386__)
#define Clear(code)
#endif

#if defined(__x86_64__)
inline void WriteMSR(uint32_t msr, uint32_t hi, uint32_t lo) {
    __asm__ volatile ("wrmsr" : : "c" (msr), "d" (hi), "a" (lo)); }
inline void WriteMSR(uint32_t msr, uintptr_t value) {
    WriteMSR(msr, value >> 32, static_cast<uint32_t>(value)); }
template <typename Type_>
inline void WriteMSR(uint32_t msr, Type_ *value) {
    WriteMSR(msr, reinterpret_cast<uintptr_t>(value)); }
#endif
// }}}

struct Page {
    Page *next_;
    uint64_t zero_[(1 << (pagebits_ - wordbits_)) - 1];
};

static_assert(sizeof(Page) == kilopage_);

struct State {
    char buffer_[kilopage_];

    uint8_t stack_[kilopage_];
    Table tables_[4];

    Page *next_, *more_;
    uintptr_t stop_;
    const void *syscalls_[500];
} __attribute__((__aligned__(kilopage_)));
// NOLINTNEXTLINE (cppcoreguidelines-avoid-non-const-global)
State state_;

static_assert((sizeof(State) % kilopage_) == 0);

uint64_t Align(uint64_t address) {
    return (address + kilopage_ - 1) & ~uint64_t(kilopage_ - 1);
}

const auto control_(static_cast<volatile uintptr_t *>(KofP(boundary_ + kilopage_)));

}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Winvalid-noreturn"
__attribute__((__noreturn__))
extern "C" void abort() {
    // NOLINTNEXTLINE(google-build-using-namespace)
    using namespace orc;
    *control_ = 1;
}
#pragma clang diagnostic pop

// memory api {{{
// NOLINTBEGIN(readability-inconsistent-declaration-parameter-name)
extern "C" void *memset(void *data, int value, size_t size) {
    for (size_t i(0); i != size; ++i)
        reinterpret_cast<char *>(data)[i] = char(value);
    return data;
}

extern "C" void *memcpy(void *dest, const void *src, size_t size) {
    for (size_t i(0); i != size; ++i)
        reinterpret_cast<char *>(dest)[i] = reinterpret_cast<const char *>(src)[i];
    return dest;
}

extern "C" size_t strlen(const char *data) {
    for (size_t size(0);; ++size)
        if (data[size] == '\0')
            return size;
}
// NOLINTEND(readability-inconsistent-declaration-parameter-name)
// }}}

#if 0
// printf {{{
namespace {
char *itoa_(uintmax_t value, char *data, unsigned int base, bool upper) {
    if (value == 0)
        *--data = '0';
    else while (value != 0) {
        const auto digit(value % base);
        value /= base;
        *--data = char(digit < 10 ? digit + '0' : digit - 10 + (upper ? 'A' : 'a'));
    }

    return data;
} }

// NOLINTBEGIN(cppcoreguidelines-pro-type-vararg)
extern "C" size_t vsnprintf(char *str, size_t max, const char *format, va_list args) {
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
extern "C" size_t snprintf(char *str, size_t size, const char *format, ...) {
    va_list args; va_start(args, format);
    auto value(vsnprintf(str, size, format, args));
    va_end(args);
    return value;
}

__attribute__((__format__ (__printf__, 1, 2)))
extern "C" size_t printf(const char *format, ...) {
    // NOLINTNEXTLINE(google-build-using-namespace)
    using namespace orc;
    va_list args; va_start(args, format);
    auto value(vsnprintf(state_.buffer_, kilopage_, format, args));
    va_end(args);
    Clear(state_.buffer_);
    *control_ = 2;
    return value;
}
// NOLINTEND(cppcoreguidelines-pro-type-vararg,cert-dcl50-cpp)

// }}}
#else
#define printf(format, ...) do {} while(false)
#endif
// debug macros {{{
#define orc_assert(code) do if (!(code)) { \
    printf("orc_assert(%s) @ %s:%u\n", #code, __FILE__, __LINE__); \
    abort(); \
} while (false)

#define orc_syscall(expr, ...) ({ \
    auto _value(expr); \
    orc_assert((long) _value != -1); \
_value; })

#define orc_trace() do { \
    printf("orc_trace() @ %s:%u\n", __FILE__, __LINE__); \
} while (false)
// }}}

// NOLINTBEGIN(performance-no-int-to-ptr)
namespace orc {

// alloc/free {{{
template <typename Type_ = void>
Type_ *palloc() {
    if (state_.next_ != nullptr) {
        const auto page(state_.next_);
        state_.next_ = page->next_;
        memset(page, 0, sizeof(Page));
        return reinterpret_cast<Type_ *>(page);
    }

    return state_.more_++;
}

void free(void *data) {
    orc_assert((reinterpret_cast<uintptr_t>(data) & MASK(pagebits_)) == 0);
    const auto page(reinterpret_cast<Page *>(data));
    page->next_ = state_.next_;
    state_.next_ = page;
}
// }}}
// exceptions {{{
void backtrace(uintptr_t lr, const uintptr_t *fp) {
#if 0 && defined(__aarch64__)
    for (;;) {
        printf("lr = 0x%lx fp = %p\n", lr, fp);
        if (fp == nullptr) break;
        lr = fp[1];
        fp = reinterpret_cast<const uintptr_t *>(fp[0]);
    }
#endif
}

extern "C" long enosys(uintptr_t nr, uintptr_t lr, uintptr_t fp) {
    printf("enosys(%lu, 0x%lx, 0x%lx)\n", nr, lr, fp);
    backtrace(lr, reinterpret_cast<const uintptr_t *>(fp));
    abort();
    return -ENOSYS;
}
// }}}
// page fault {{{
#if defined(__aarch64__)
extern "C" uintptr_t efault(uintptr_t sr, uintptr_t lr, uintptr_t fp, uintptr_t x0) {
    // https://developer.arm.com/documentation/ddi0595/2021-12/AArch64-Registers/ESR-EL1--Exception-Syndrome-Register--EL1-?lang=en#fieldset_0-24_0_10
    printf("efault(0x%lx, 0x%lx, 0x%lx, 0x%lx)\n", sr, lr, fp, x0);
    backtrace(lr, reinterpret_cast<const uintptr_t *>(fp));
    abort();
    return x0;
}
#endif
// }}}
// page table {{{
template <bool Full_, size_t Level_ = 4>
[[nodiscard]] bool Scan_(uintptr_t &entry, uintptr_t address, const auto &code) {
    //printf("Scan_<%s, %ld>(%p = %lx, 0x%lx)\n", Full_ ? "true" : "false", Level_, &entry, entry, address << pagebits_);
    static_assert(Level_ <= 4);
    if constexpr (Level_ == 0)
        return (Full_ || entry != 0) && code(address << pagebits_, entry);
    else {
        if constexpr (Level_ != 4) if (!isE(entry))
            if constexpr (Full_) {
                entry = TofP(PofK(palloc()));
                Clear(&entry);
            } else return false;

        auto index((address >> (indxbits_ * (Level_ - 1))) & MASK(indxbits_));
        auto &table(*KofP<Table>(PofE(entry)));
        if (Scan_<Full_, Level_ - 1>(table[index], address, code))
            return true;
        address = address & ~MASK(indxbits_ * Level_);

        const auto limit(1 << (indxbits_
#if defined(__x86_64__)
            - (Level_ == 4 ? 1 : 0)
#endif
        ));

        for (++index; index != limit; ++index)
            if (Scan_<Full_, Level_ - 1>(table[index], address + (index << (indxbits_ * (Level_ - 1))), code))
                return true;
        return false;
    }
}

template <bool Full_, typename Code_>
[[nodiscard]] bool Scan(uintptr_t base, const Code_ &code) {
    orc_assert((base & MASK(pagebits_)) == 0);
    orc_assert(intptr_t(base) >= 0);

    uintptr_t table;
#if 0
#elif defined(__aarch64__)
    __asm__ volatile ("mrs %0, ttbr0_el1" : "=r" (table));
#elif defined(__x86_64__)
    __asm__ volatile ("mov %%cr3, %0" : "=r" (table));
#else
#error
#endif

    return Scan_<Full_>(table, base >> pagebits_, code);
}

template <bool Full_, typename Code_>
void Scan(uintptr_t base, size_t size, const Code_ &code) {
    if (size == 0) return;
    orc_assert((size & MASK(pagebits_)) == 0);
    orc_assert(base == 0 || size < -base);

    const auto done(Scan<Full_>(base, [&](uintptr_t page, uintptr_t &entry) {
        if (page >= base + size)
            return true;
        code(page, entry);

        // XXX: this forces page commit even when it makes no sense
        if (entry != 0 && !isE(entry)) {
            orc_assert(PofE(entry) == holdpage_);
            entry = entry & ~nextmask_ | PofK(palloc()) | 0x1;
        }

        Clear(&entry);

#if 0
#elif defined(__aarch64__)
        // XXX: https://forum.osdev.org/viewtopic.php?t=36412&p=303237
        // ^ I think that low bit in the TTBR is some part of MMU.IRGN
        __asm__ volatile ("dsb ishst");
        __asm__ volatile ("tlbi vae1is, %0" : : "p" (page>>pagebits_));
        __asm__ volatile ("tlbi vae1is, %0" : : "p" (page>>pagebits_ | 1ull<<48));
        __asm__ volatile ("dsb ish");
        __asm__ volatile ("isb");
#elif defined(__x86_64__)
        __asm__ volatile ("invlpg %0" : : "p" (page));
#else
#error
#endif

        //printf("page 0x%lx now 0x%lx\n", page, entry);
        return false;
    }));
    orc_assert(done);
}
// }}}
// memory map {{{
constexpr Entry RofF(unsigned flags) {
    return RofF((flags & PROT_WRITE) != 0, (flags & PROT_EXEC) != 0);
}

uintptr_t $mmap(uintptr_t base, size_t size, int prot, int flags, int file, size_t offset) {
    //printf("mmap(0x%lx, 0x%lx, %u, %u, %d, %zu)\n", base, size, prot, flags, file, offset);
    orc_assert((prot & ~(PROT_READ | PROT_WRITE | PROT_EXEC)) == 0);
    orc_assert((flags & ~(MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED | MAP_NORESERVE)) == 0);
    orc_assert((flags & MAP_PRIVATE) != 0);
    orc_assert((flags & MAP_ANONYMOUS) != 0);
    orc_assert(file == -1);
    orc_assert(offset == 0);

    const auto rest(RofF(prot));

    if ((flags & MAP_FIXED) == 0)
        if (!Scan<false>(base, [&](uintptr_t page, uintptr_t &entry) {
            if (page - base >= size)
                return true;
            base = page + kilopage_;
            return false;
        })) {
            // XXX: verify that base has sufficient size before end of memory
        }

    Scan<true>(base, size, [&](uintptr_t page, uintptr_t &entry) {
        if (isE(entry)) free(KofP(PofE(entry)));
        entry = rest | holdpage_;
    });

    return base;
}

long $madvise(uintptr_t base, size_t size, int advice) {
    orc_assert(advice == MADV_DONTNEED || advice == MADV_FREE);

    Scan<true>(base, size, [&](uintptr_t page, uintptr_t &entry) {
        orc_assert(entry != 0);
        if (isE(entry)) free(KofP(PofE(entry)));
        entry = entry & restmask_ | holdpage_;
    });

    return 0;
}

long $munmap(uintptr_t base, size_t size) {
    //printf("munmap(0x%lx, 0x%lx)\n", base, size);

    Scan<false>(base, size, [&](uintptr_t page, uintptr_t &entry) {
        if (isE(entry)) free(KofP(PofE(entry)));
        entry = 0;
    });

    return 0;
}

// XXX: limit areas of memory subject to this syscall
long $mprotect(uintptr_t base, size_t size, int prot) {
    const auto rest(RofF(prot));

    Scan<true>(base, size, [&](uintptr_t page, uintptr_t &entry) {
        orc_assert(entry != 0);
        entry = entry & ~restmask_ | rest;
    });

    return 0;
}

uintptr_t $brk(uintptr_t brk) {
    //printf("brk(0x%lx) @ 0x%lx\n", brk, state_.stop_);
    if (brk == 0)
        return state_.stop_;

    const auto before(Align(state_.stop_));
    const auto after(Align(brk));
    // XXX: limit after to user-accessible memory

    if (before < after)
        $mmap(before, after - before, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    else
        $munmap(after, before - after);

    // XXX: maybe zero memory within the same page
    return state_.stop_ = brk;
}
// }}}

long $prlimit64(pid_t pid, int resource, const struct rlimit *new_limit, struct rlimit *old_limit) {
    orc_assert(pid == 0);
    orc_assert(resource == RLIMIT_STACK);
    orc_assert(new_limit == nullptr);

    old_limit->rlim_cur = 8192ul*1024ul;
    old_limit->rlim_max = RLIM64_INFINITY;
    return 0;
}

long $exit_group(int status) {
    printf("exit_group(0x%x)\n", status);
    abort();
}

bool isU(const void *data, size_t size) {
    return reinterpret_cast<intptr_t>(data) >= 0 &&
        reinterpret_cast<const uint8_t *>(data) + size >= data;
}

#ifdef __x86_64__
long $arch_prctl(int code, unsigned long address) {
    switch (code) {
        case ARCH_SET_FS:
            WriteMSR(0xC0000100 /*fsbase*/, address);
            return 0;
        case 0x3001: // ARCH_CET_STATUS
            return -EINVAL;
        default:
            orc_assert(false);
    }
}
#endif

size_t $write(int fd, const void *data, size_t size) {
    printf("write(%d, %p, %zu)\n", fd, data, size);
    orc_assert(fd == 1 || fd == 2);
    orc_assert(isU(data, size));
    orc_assert(size <= kilopage_ - 1);
    memcpy(state_.buffer_, data, size);
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index)
    state_.buffer_[size] = '\0';
    Clear(state_.buffer_);
    *control_ = 2;
    return size;
}

// system dispatcher {{{
__attribute__((__naked__))
void service() {
    __asm__ volatile ( // dispatch system call table
// XXX: implement frame pointers
#if 0
#elif defined(__aarch64__)
// https://stackoverflow.com/questions/261419/what-registers-to-save-in-the-arm-c-calling-convention
// XXX: consider -ffixed-xX to avoid saving a few temporary registers
// XXX: merge stack pointer update to save a couple instructions
    R"(
        sub sp, sp, #0x90

        stp x30, x1, [sp, #0x00]
        stp x2, x3, [sp, #0x10]
        stp x4, x5, [sp, #0x20]
        stp x6, x7, [sp, #0x30]

        stp x8, x9, [sp, #0x40]
        stp x10, x11, [sp, #0x50]
        stp x12, x13, [sp, #0x60]
        stp x14, x15, [sp, #0x70]

        stp x16, x17, [sp, #0x80]

        mrs x16, esr_el1
        mov x17, #0x56000000
        cmp x16, x17
        b.ne .Lnotsvc

        cmp x8, %1
        b.ge .Lenosys

        adr x16, %0
        ldr x16, [x16, x8, lsl #3]

        cmp x16, #0
        b.eq .Lenosys

        blr x16
      .Lreturn:

        ldp x16, x17, [sp, #0x80]

        ldp x14, x15, [sp, #0x70]
        ldp x12, x13, [sp, #0x60]
        ldp x10, x11, [sp, #0x50]
        ldp x8, x9, [sp, #0x40]

        ldp x6, x7, [sp, #0x30]
        ldp x4, x5, [sp, #0x20]
        ldp x2, x3, [sp, #0x10]
        ldp x30, x1, [sp, #0x00]

        add sp, sp, #0x90
        eret

      .Lenosys:
        mov x0, x8
        mrs x1, elr_el1
        mov x2, x29
        bl enosys
        b .Lreturn

      .Lnotsvc:
        mov x3, x0
        mov x0, x16
        mrs x1, elr_el1
        mov x2, x29
        bl efault
        b .Lreturn
    )" : : "i" (state_.syscalls_), "i" (sizeof(state_.syscalls_) / sizeof(*state_.syscalls_))
#elif defined(__x86_64__)
// https://wiki.osdev.org/SYSENTER
// https://www.felixcloutier.com/x86/syscall.html
// https://www.felixcloutier.com/x86/sysret.html
// https://stackoverflow.com/questions/2535989/what-are-the-calling-conventions-for-unix-linux-system-calls-and-user-space-f
// https://stackoverflow.com/questions/18024672/what-registers-are-preserved-through-a-linux-x86-64-function-call
    R"(
        mov %%rsp, (%c2-0x16)
        mov $(%c2-0x16), %%rsp

        push %%rcx; push %%rdx
        push %%rsi; push %%rdi

        push %%r8; push %%r9
        push %%r10; push %%r11

        cmp %1, %%rax
        jge abort

        mov %0, %%rcx
        mov (%%rcx, %%rax, 8), %%rax

        cmp $0, %%rax
        je abort

        mov %%r10, %%rcx
        call *%%rax

        pop %%r11; pop %%r10
        pop %%r9; pop %%r8

        pop %%rdi; pop %%rsi
        pop %%rdx; pop %%rcx

        // XXX: protect interrupts!!
        pop %%rsp
        sysretq
    )" : : "i" (state_.syscalls_), "i" (sizeof(state_.syscalls_) / sizeof(*state_.syscalls_)), "i" (state_.tables_)
#else
#error
#endif
    );
}
// }}}
// executable loader {{{
extern "C" void main() {
    state_.tables_[0][0] = 0x0;
    state_.tables_[0][1] = 0x0;
    Clear(state_.tables_[0]);

    state_.more_ = reinterpret_cast<Page *>(&state_ + 1);
    // XXX: randomize this address
    state_.stop_ = 0x555555b2d000;

    state_.syscalls_[__NR_mmap] = reinterpret_cast<const void *>(&$mmap);
    state_.syscalls_[__NR_madvise] = reinterpret_cast<const void *>(&$madvise);
    state_.syscalls_[__NR_munmap] = reinterpret_cast<const void *>(&$munmap);
    state_.syscalls_[__NR_mprotect] = reinterpret_cast<const void *>(&$mprotect);
    state_.syscalls_[__NR_brk] = reinterpret_cast<const void *>(&$brk);

    state_.syscalls_[__NR_prlimit64] = reinterpret_cast<const void *>(&$prlimit64);
    state_.syscalls_[__NR_exit_group] = reinterpret_cast<const void *>(&$exit_group);
#if defined(__x86_64__)
    state_.syscalls_[__NR_arch_prctl] = reinterpret_cast<const void *>(&$arch_prctl);
#endif

    state_.syscalls_[__NR_write] = reinterpret_cast<const void *>(&$write);

    const auto null(orc_syscall($mmap(0, megapage_, 0, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0)));
    orc_assert(null == 0);

    const uint64_t slide(megapage_);

    extern const unsigned char _binary_worker_start[];
    const auto &header(*reinterpret_cast<const Elf64_Ehdr *>(_binary_worker_start));
    const uint64_t entry(header.e_entry + slide);
    const auto commands(reinterpret_cast<const Elf64_Phdr *>(_binary_worker_start + header.e_phoff));
    for (size_t i(0); i != header.e_phnum; ++i)
        if (const auto &command(commands[i]); command.p_type == PT_LOAD) {
            // https://forum.osdev.org/viewtopic.php?t=48082&p=328893
            // https://stackoverflow.com/questions/76795394/why-are-there-overlapping-and-misaligned-segments-in-a-simple-elf-binary
            const auto offset(command.p_vaddr & uint64_t(command.p_align - 1));

            const auto data(command.p_offset - offset + _binary_worker_start);
            const auto size(Align(command.p_filesz + offset));

            const auto start(command.p_vaddr - offset + slide);
            const auto total(Align(command.p_memsz + offset));

            orc_assert(total >= size);

            const auto writable((command.p_flags & PF_W) != 0);
            const auto rest(RofF(writable, (command.p_flags & PF_X) != 0));

            if (!writable)
                Scan<true>(start, size, [&](uintptr_t page, uintptr_t &entry) {
                    orc_assert(entry == 0);
                    const auto back(data + (page - start));

                    entry = rest | PofK(back) | 0x1;
                });
            else {
                Scan<true>(start, size, [&](uintptr_t page, uintptr_t &entry) {
                    orc_assert(entry == 0);
                    const auto back(data + (page - start));

                    const auto copy(palloc());
                    memcpy(copy, back, kilopage_);
                    entry = rest | PofK(copy) | 0x1;
                });

                memset(reinterpret_cast<void *>(start), 0, offset);
                memset(reinterpret_cast<void *>(start + offset + command.p_filesz), 0, size - offset - command.p_filesz);
            }

            Scan<true>(start + size, total - size, [&](uintptr_t page, uintptr_t &entry) {
                orc_assert(entry == 0);
                entry = rest;
            });
        }

    struct rlimit limit{};
    $prlimit64(0, RLIMIT_STACK, nullptr, &limit);
    const size_t size(limit.rlim_cur);

    auto stack(reinterpret_cast<uintptr_t *>(reinterpret_cast<uint8_t *>(orc_syscall($mmap(0, size, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0))) + size));

    // NOLINTBEGIN(clang-analyzer-core.NullDereference)

    // https://articles.manugarg.com/aboutelfauxiliaryvectors
    // https://lwn.net/Articles/519085/

    // random
    // XXX: https://xkcd.com/221/
    // chosen by fair dice roll.
    // guaranteed to be random.
    *--stack = 0x4444444444444444;
    *--stack = 0x4444444444444444;
    const auto random(stack);

    // auxv
    *--stack = AT_NULL;
    *--stack = reinterpret_cast<uintptr_t>(random);
    *--stack = AT_RANDOM;

    // envp
    *--stack = 0;

    // argv
    *--stack = 0;

    // argc
    *--stack = 0;

    // NOLINTEND(clang-analyzer-core.NullDereference)

    const auto atexit(nullptr);


#if defined(__x86_64__)
    WriteMSR(0xC0000081 /*star*/, (0x8*3<<16)|(0x8*1), 0);
    // arch/x86/kernel/cpu/common.c // XXX: deal with $0x100
    WriteMSR(0xC0000082 /*lstar*/, &service);
    WriteMSR(0xC0000084 /*sfmask*/, 0x0, 0x257ED5);
#endif

    __asm__ volatile ( // jump to userland entrypoint
#if 0
#elif defined(__aarch64__)
    // sysdeps/aarch64/start.S
    R"(
        adr x0, vectors
        msr vbar_el1, x0

        mov sp, %4

        mov x0, %2

        msr sp_el0, %0
        msr elr_el1, %1
        msr spsr_el1, xzr
        eret

        // XXX: this is wasting a ton of space
        .balign 0x800
      vectors:
        .space 0x200
        .space 0x200
        b %3
        .balign 0x80
        .space 0x380
    )" : : "r" (stack), "r" (entry), "i" (atexit), "i" (service), "r" (state_.tables_) : "x0"
#elif defined(__x86_64__)
    // sysdeps/x86_64/start.S

    // https://old.reddit.com/r/osdev/comments/clump5/is_it_okay_to_use_null_descriptor_for_ds_es_and/
    // https://forum.osdev.org/viewtopic.php?f=1&t=22826
    // https://en.wikipedia.org/wiki/FLAGS_register
    // XXX: https://news.ycombinator.com/item?id=12552834

    R"(
        mov %2, %%rdx

        push $0x08*4+0x3 // ss
        push %0 // sp
        // XXX: copy 0x100 from current flags?
        push $0x202 // rflags
        push $0x08*5+0x3 // cs
        push %1 // ip
        iretq
    )" : : "r" (stack), "r" (entry), "i" (atexit) : "rax", "rcx", "rdx"
#else
#error
#endif
    );
}
// }}}
// kernel bootloader {{{
__attribute__((__naked__))
extern "C" void _start() {
    __asm__ volatile ( // setup memory configuration
#if 0
#elif defined(__aarch64__)
    R"(
        // set stack pointer
        adr x0, %0
        mov sp, x0

        mrs x0, cpacr_el1
        // enable Advanced SIMD
        orr x0, x0, #0x300000
        msr cpacr_el1, x0

        // initialize page tables
        adr x0, %0
        bl setup

        mov x0, #0x0
        // enable 4-level EL0 paging
        orr x0, x0, #0x00000010
        // enable 4-level EL1 paging
        orr x0, x0, #0x00100000
        // use 4kB EL1 page granule
        orr x0, x0, #0x80000000
        msr tcr_el1, x0

        // memory attribute index 0
        mov x0, #0xff
        msr mair_el1, x0

        // set page table pointers
        adr x0, %0
        add x0, x0, 0x2000
        msr ttbr0_el1, x0
        add x0, x0, 0x1000
        msr ttbr1_el1, x0
        isb

        mrs x0, sctlr_el1
        // enable paging (MMU)
        orr x0, x0, #0x0001 // M
        // enable data/unified caches
        orr x0, x0, #0x0004 // C
        // enable EL1 stack alignment
        orr x0, x0, #0x0008 // SA
        // enable EL0 stack alignment
        orr x0, x0, #0x0010 // SA0
        // enable instruction cache
        orr x0, x0, #0x1000 // I
        // enable EL0 ctr_ell1 access
        orr x0, x0, #0x8000 // UCT
        // enable EL0 dc cva access
        orr x0, x0, #0x4000000 // UCI
        msr sctlr_el1, x0
        isb

        mov x0, %1

        // use high stack pointer
        add sp, sp, x0

        // jump to high kernel
        adr x1, %2
        add x1, x1, x0
        br x1
    )"
#elif defined(__x86_64__)
    // https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html#x86Operandmodifiers
    R"(
        // start in 32-bit protected mode
        .code32
        mov $_start-%c1, %%ebx
        sub %%ecx, %%ebx

        mov %%cr4, %%eax
        // enable 4-level paging
        or $(1<<5), %%eax
        // enable SSE instructions
        or $(1<<9), %%eax
        // enable SSE exceptions
        or $(1<<10), %%eax
        // XXX: consider CET / PKS
        mov %%eax, %%cr4

        // set stack pointer
        mov %0-%c1, %%eax
        sub %%ebx, %%eax
        mov %%eax, %%esp

        // initialize page tables
        mov %0-%c1, %%eax
        sub %%ebx, %%eax
        call __regcall3__setup

        // enable extended features
        mov $0xC0000080, %%ecx // efer
        rdmsr
        // enable syscall/sysret
        or $(1<<0), %%eax
        // enable long mode
        or $(1<<8), %%eax
        // enable no-execute
        or $(1<<11), %%eax
        wrmsr

        // set page table pointer
        mov %0-%c1, %%eax
        sub %%ebx, %%eax
        add $0x2000, %%eax
        mov %%eax, %%cr3

        mov %%cr0, %%eax
        // enable numeric error
        or $(1<<5), %%eax
        // enable write protect
        or $(1<<16), %%eax
        // disable no-writethrough
        and $~(1<<29), %%eax
        // disable cache disable
        and $~(1<<30), %%eax
        // enable paging
        or $(1<<31), %%eax
        mov %%eax, %%cr0

        // low address descriptor
        mov %0-%c1, %%eax
        sub %%ebx, %%eax
        add $0x3000, %%eax
        push %%eax
        pushw $0xfff
        lgdt (%%esp)
        add $0x6, %%esp

        // jump to 64-bit segment
        jmp $0x08*1, $code64-%c1
      code64:
        .code64

        // high address descriptor
        mov %0, %%rax
        add $0x3000, %%rax
        push %%rax
        pushw $0xfff
        lgdt (%%rsp)
        add $0xa, %%rsp

        // clear segment registers
        //mov $0x0, %%ax
        //mov %%ax, %%ds
        //mov %%ax, %%es
        //mov %%ax, %%fs
        //mov %%ax, %%gs

        // set stack segment
        //mov $0x08*2, %%ss

        // use high stack pointer
        mov %%rsp, %%rax
        addq %1, %%rax
        mov %%rax, %%rsp

        // jump to high kernel
        mov %2, %%rax
        sub %%rbx, %%rax
        jmp *%%rax
    )"
#else
#error
#endif
    : : "i" (state_.tables_), "i" (-boundary_ - gigapage_), "i" (main));
}
// }}}
// x86_64 entrypoint {{{
#if defined(__x86_64__)
__asm__ (R"( // x86 32-bit qemu entrypoint
.pushsection .note.Xen, "a"
.balign 4
.long 2f - 1f
.long 4484f - 3f
.long 18 // XEN_ELFNOTE_PHYS32_ENTRY
1:.asciz "Xen"
2:.balign 4
// XXX: maybe merge this with makefile
3:.quad _start - 0xffffffffc0000000
4484:.balign 4
.popsection
)");
#endif
// }}}

}
// NOLINTEND(performance-no-int-to-ptr)
