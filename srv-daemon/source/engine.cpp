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


#include <csignal>
#include <iostream>

#include <fcntl.h>

#include <sys/ioctl.h>
#include <sys/mman.h>

#include <elf.h>

#include <linux/kvm.h>

#include "buffer.hpp"
#include "scope.hpp"
#include "syscall.hpp"
#include "time.hpp"

#include "load.hpp"

extern const unsigned char _binary_kernel_start[];

// XXX: move this somewhere and maybe find a library
namespace gsl { template <typename Type_> using owner = Type_; }

// NOLINTBEGIN(cppcoreguidelines-pro-type-vararg)
namespace orc {

// XXX: stand-in
typedef int Fd;

int Engine() {
    static const size_t megabyte(1ULL*1024*1024);

    struct sigaction action{};
    memset(&action, 0, sizeof(action));
    action.sa_handler = [](int) {};
    orc_syscall(sigaction(SIGUSR1, &action, nullptr));


    const Fd zygote(memfd_create("zygote", MFD_CLOEXEC));
    const size_t arena(768*megabyte);
    orc_syscall(ftruncate(zygote, arena));

    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-cstyle-cast,performance-no-int-to-ptr)
    const auto memory(reinterpret_cast<uint8_t *>(orc_syscall(mmap(nullptr, arena, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_SHARED, zygote, 0))));


    const auto [limit, entry] = [&]() {
        const auto ident(reinterpret_cast<const uint8_t *>(_binary_kernel_start));
        orc_assert(memcmp(ident, ELFMAG, SELFMAG) == 0);
        orc_assert(ident[EI_DATA] == ELFDATA2LSB);
        orc_assert(ident[EI_VERSION] == EV_CURRENT);
        orc_assert(ident[EI_OSABI] == ELFOSABI_NONE);

        const auto load([&]<typename Elf_Ehdr, typename Elf_Phdr>() -> std::tuple<uintptr_t, uintptr_t> {
            const auto &header(*reinterpret_cast<const Elf_Ehdr *>(_binary_kernel_start));
            const auto commands(reinterpret_cast<const Elf_Phdr *>(_binary_kernel_start + header.e_phoff));

            uintptr_t offset(0);
            uintptr_t limit(0);
            uintptr_t entry(-1);

            for (size_t i(0); i != header.e_phnum; ++i)
                if (const auto &command(commands[i]); command.p_type == PT_LOAD) {
                    orc_assert_(limit == 0, "non-final zero-initialized segment");
                    if (command.p_filesz == 0)
                        limit = command.p_vaddr - offset;
                    else {
                        orc_assert_(command.p_filesz == command.p_memsz, "non-fully zero-initialized segment");
                        const uintptr_t current(command.p_vaddr - command.p_offset);
                        if (offset == 0)
                            offset = current;
                        else
                            orc_assert_(offset == current, "inconsistent segment offset for mapping");
                    }

                    if (header.e_entry >= command.p_vaddr && header.e_entry < command.p_vaddr + command.p_memsz)
                        entry = header.e_entry - command.p_vaddr + command.p_offset;
                }

            orc_assert_(limit != 0, "unable to determine block starting point");
            orc_assert_(entry != -1, "entrypoint outside of kernel section");

            return {(limit + 0xfffull) & ~0xfffull, entry};
        });

        switch (const auto value = ident[EI_CLASS]) {
            #define caseELF(bits) case ELFCLASS##bits: \
                return load.operator ()<Elf##bits##_Ehdr, Elf##bits##_Phdr>();
            caseELF(32) caseELF(64) default:
                orc_assert_(false, "unknown EI_CLASS " << unsigned(value));
        }
    }();

    //std::cout << "limit: " << std::hex << limit << std::endl;
    //std::cout << "entry: " << std::hex << entry << std::endl;


    const Fd kvm(orc_syscall(open("/dev/kvm", O_RDWR | O_CLOEXEC)));
    orc_assert(orc_syscall(ioctl(kvm, KVM_GET_API_VERSION, nullptr)) == 12);
    const auto size(orc_syscall(ioctl(kvm, KVM_GET_VCPU_MMAP_SIZE, nullptr)));

    const auto vm(orc_syscall(ioctl(kvm, KVM_CREATE_VM, 0)));
    const auto cpu(orc_syscall(ioctl(vm, KVM_CREATE_VCPU, 0)));
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-cstyle-cast,performance-no-int-to-ptr)
    const auto run(static_cast<struct kvm_run *>(orc_syscall(mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_SHARED, cpu, 0))));

#if 0
#elif defined(__aarch64__)
    struct kvm_vcpu_init cpuid{};
    cpuid.target = KVM_ARM_TARGET_GENERIC_V8;
#elif defined(__x86_64__)
    // XXX: implement allocation loop using cpuid: label
    const decltype(std::declval<struct kvm_cpuid2 *>()->nent) cpuids(128);
    // NOLINTBEGIN(cppcoreguidelines-no-malloc,cppcoreguidelines-owning-memory)
    const auto cpuid(static_cast<struct kvm_cpuid2 *>(malloc(sizeof(struct kvm_cpuid2) + cpuids * sizeof(struct kvm_cpuid_entry2))));
    _scope({ free(cpuid); });
    // NOLINTEND(cppcoreguidelines-no-malloc,cppcoreguidelines-owning-memory)
    cpuid->nent = cpuids;
    orc_syscall(ioctl(kvm, KVM_GET_SUPPORTED_CPUID, cpuid));

    for (decltype(cpuid->nent) i(0); i != cpuid->nent; ++i) {
        // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-constant-array-index)
        auto &entry(cpuid->entries[i]);
        switch (entry.function) {
            // supports long mode
            case 0x80000001:
                orc_assert((entry.edx & (1 << 29)) != 0);
                break;
        }
    }
#else
#error
#endif

#if 0
#elif defined(__aarch64__)
    orc_syscall(ioctl(cpu, KVM_ARM_VCPU_INIT, &cpuid));
#elif defined(__x86_64__)
    orc_syscall(ioctl(cpu, KVM_SET_CPUID2, cpuid));
#else
#error
#endif


    // XXX: this will be obsolete once I finish the full kASLR support
#if 0
#elif defined(__aarch64__)
    const uintptr_t base(0x40000000);
#elif defined(__x86_64__)
    const uintptr_t base(0x00000000);
#else
#error
#endif

    // kASLR is a sham and it has never stopped me from hacking anything
    // https://forums.grsecurity.net/viewtopic.php?f=7&t=3367
    // XXX: I do want it to work, though, and need to put more effort in
    const auto slide(base + 0x200000);

    {
        struct kvm_userspace_memory_region region{};
        region.slot = 0;
        region.flags = KVM_MEM_READONLY;
        region.guest_phys_addr = slide;
        region.memory_size = limit;
        region.userspace_addr = reinterpret_cast<uintptr_t>(_binary_kernel_start);
        orc_syscall(ioctl(vm, KVM_SET_USER_MEMORY_REGION, &region));
    }

    {
        // XXX: memfd memslot https://lwn.net/Articles/879370/
        struct kvm_userspace_memory_region region{};
        region.slot = 1;
        region.flags = 0;
        region.guest_phys_addr = slide + limit;
        region.memory_size = arena;
        region.userspace_addr = reinterpret_cast<uintptr_t>(memory);
        orc_syscall(ioctl(vm, KVM_SET_USER_MEMORY_REGION, &region));
    }


    {
#if 0
#elif defined(__aarch64__)
        struct kvm_one_reg reg{};
        uintptr_t value;
        reg.addr = reinterpret_cast<uintptr_t>(&value);

        reg.id = KVM_REG_ARM64 | KVM_REG_SIZE_U64 | KVM_REG_ARM_CORE | KVM_REG_ARM_CORE_REG(regs.pc);
        value = slide + entry;
        orc_syscall(ioctl(cpu, KVM_SET_ONE_REG, &reg));
#elif defined(__x86_64__)
        struct kvm_sregs sregs{};
        orc_syscall(ioctl(cpu, KVM_GET_SREGS, &sregs));

        struct kvm_segment seg{
            .base = 0, .limit = 0xffffffff,
            .selector = 1 << 3, .type = 0xb,
            .present = 1, .dpl = 0, .db = 1,
            .s = 1, .l = 0, .g = 1,
        };

        sregs.cs = seg;
        seg.selector = 2 << 3; seg.type = 0x3;
        sregs.ds = seg; sregs.es = seg;
        sregs.fs = seg; sregs.gs = seg;
        sregs.ss = seg;

        sregs.cr0 |= 0x1;
        orc_syscall(ioctl(cpu, KVM_SET_SREGS, &sregs));

        struct kvm_regs regs{};
        orc_syscall(ioctl(cpu, KVM_GET_REGS, &regs));
        regs.rip = regs.rcx = slide + entry;
        regs.rflags = 0x2;
        orc_syscall(ioctl(cpu, KVM_SET_REGS, &regs));
#else
#error
#endif
    }


    const auto dump([&]() {
#if 0
#elif defined(__aarch64__)
        // XXX: cache this list
        std::vector<uint64_t> regs;
        regs.resize(1024);
        regs[0] = regs.size() - 1;
        orc_syscall(ioctl(cpu, KVM_GET_REG_LIST, regs.data()));

        //v=0xc290; z=[14,11,7,3,0]; [(v>>b)&((1<<(a-b))-1) for a,b in zip(([16]+z)[:-1],z)]

        struct kvm_one_reg reg{};
        uintptr_t value;
        reg.addr = reinterpret_cast<uintptr_t>(&value);

        for (size_t i(0); i != regs[0]; ++i) {
            reg.id = regs[i+1];
            if ((reg.id & KVM_REG_ARM_COPROC_MASK) != KVM_REG_ARM_CORE)
                continue;
            orc_syscall(ioctl(cpu, KVM_GET_ONE_REG, &reg));
            // XXX: I really want register names :/
            std::cout << std::hex << reg.id << " " << value << std::endl;
        }
#elif defined(__x86_64__)
        struct kvm_regs regs{};
        orc_syscall(ioctl(cpu, KVM_GET_REGS, &regs));
        std::cout << std::hex;
        std::cout << "ax " << regs.rax << std::endl;
        std::cout << "bx " << regs.rbx << std::endl;
        std::cout << "cx " << regs.rcx << std::endl;
        std::cout << "dx " << regs.rdx << std::endl;
        std::cout << "si " << regs.rsi << std::endl;
        std::cout << "di " << regs.rdi << std::endl;
        std::cout << "sp " << regs.rsp << std::endl;
        std::cout << "bp " << regs.rbp << std::endl;
        std::cout << "r8 " << regs.r8 << std::endl;
        std::cout << "r9 " << regs.r9 << std::endl;
        std::cout << "rA " << regs.r10 << std::endl;
        std::cout << "rB " << regs.r11 << std::endl;
        std::cout << "rC " << regs.r12 << std::endl;
        std::cout << "rD " << regs.r13 << std::endl;
        std::cout << "rE " << regs.r14 << std::endl;
        std::cout << "rF " << regs.r15 << std::endl;
        std::cout << "ip " << regs.rip << std::endl;
        std::cout << "fl " << regs.rflags << std::endl;
#endif
        std::cout << std::endl;
    }); (void) dump;

    const auto buffer(reinterpret_cast<char *>(memory));

    if (false) {
        // this is mostly useful for debugging esrly kASLR
        struct kvm_guest_debug debug{};
        debug.control = KVM_GUESTDBG_ENABLE | KVM_GUESTDBG_SINGLESTEP;
        orc_syscall(ioctl(cpu, KVM_SET_GUEST_DEBUG, &debug));
    }

    for (;;) {
        orc_syscall(ioctl(cpu, KVM_RUN, nullptr), EINTR);
        switch (run->exit_reason) {
            case KVM_EXIT_INTR:
                std::cout << "INTR" << std::endl;
                dump();
                break;

            case KVM_EXIT_MMIO: {
                orc_assert_(run->mmio.phys_addr == base + 0x1000, "mmio: 0x" << std::hex << run->mmio.phys_addr);
                orc_assert(run->mmio.is_write);
                orc_assert(run->mmio.len == sizeof(uintptr_t));
                switch (const auto command = *reinterpret_cast<const uintptr_t *>(run->mmio.data)) {
                    case 0: case 1: {
                        struct kvm_guest_debug debug{};
                        debug.control = command == 0 ? 0 : KVM_GUESTDBG_ENABLE | KVM_GUESTDBG_SINGLESTEP;
                        debug.control = 0;
                        orc_syscall(ioctl(cpu, KVM_SET_GUEST_DEBUG, &debug));
                    } break;
                    case 2: {
                        std::cout << "abort()" << std::endl;
                        return 0;
                    } break;
                    case 3: {
                        std::cout << buffer << std::flush;
                    } break;
                    default:
                        std::cout << "MMIO 0x" << std::hex << command << std::endl;
                    break;
                }
            } break;

            case KVM_EXIT_DEBUG: {
                dump();
            } break;

            case KVM_EXIT_IO: {
                dump();
                std::cout << run->io.direction << std::endl;
            } break;

            case KVM_EXIT_HLT:
                std::cout << "HLT" << std::endl;
                return 0;
            case KVM_EXIT_SHUTDOWN:
                dump();
                std::cout << "SHUTDOWN" << std::endl;
                return 0;
            case KVM_EXIT_FAIL_ENTRY:
                std::cout << "FAIL_ENTRY" << std::endl;
                return 0;

            case KVM_EXIT_INTERNAL_ERROR:
                orc_insist_(false, "kvm internal error");
            default: orc_insist_(false, "unknown reason: " << run->exit_reason);
        }
    }

    return 0;
}

}
// NOLINTEND(cppcoreguidelines-pro-type-vararg)
