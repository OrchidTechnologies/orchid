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
#include "kernel.hpp"
#include "scope.hpp"
#include "syscall.hpp"
#include "time.hpp"

#include "load.hpp"

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
    const size_t physical(64*megabyte);
    orc_syscall(ftruncate(zygote, physical));


    const Fd kvm(orc_syscall(open("/dev/kvm", O_RDWR | O_CLOEXEC)));
    orc_assert(orc_syscall(ioctl(kvm, KVM_GET_API_VERSION, nullptr)) == 12);
    const auto size(orc_syscall(ioctl(kvm, KVM_GET_VCPU_MMAP_SIZE, nullptr)));

    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-cstyle-cast,performance-no-int-to-ptr)
    const auto memory(reinterpret_cast<uint8_t *>(orc_syscall(mmap(nullptr, physical, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_SHARED, zygote, 0))));
    //madvise(memory, physical, MADV_MERGEABLE);

    const auto &header(*reinterpret_cast<const Elf64_Ehdr *>(kernel_data));
    const uint64_t entry(header.e_entry);
    const auto commands(reinterpret_cast<const Elf64_Phdr *>(kernel_data + header.e_phoff));
    for (size_t i(0); i != header.e_phnum; ++i)
        if (const auto &command(commands[i]); command.p_type == PT_LOAD)
            memcpy(memory + command.p_paddr, kernel_data + command.p_offset, command.p_filesz);


    const auto vm(orc_syscall(ioctl(kvm, KVM_CREATE_VM, 0)));
    const auto cpu(orc_syscall(ioctl(vm, KVM_CREATE_VCPU, 0)));
    // NOLINTNEXTLINE(cppcoreguidelines-pro-type-cstyle-cast,performance-no-int-to-ptr)
    const auto run(static_cast<struct kvm_run *>(orc_syscall(mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_SHARED, cpu, 0))));


    struct kvm_userspace_memory_region region = {};
    region.slot = 0;
    region.flags = 0;
    region.guest_phys_addr = 0x0;
    region.memory_size = physical;
    region.userspace_addr = reinterpret_cast<uintptr_t>(memory);
    orc_syscall(ioctl(vm, KVM_SET_USER_MEMORY_REGION, &region));

#ifdef __aarch64__
    struct kvm_vcpu_init init = {};
    init.target = KVM_ARM_TARGET_GENERIC_V8;
    orc_syscall(ioctl(cpu, KVM_ARM_VCPU_INIT, &init));

    struct kvm_one_reg reg = {};
    uintptr_t value;
    reg.addr = reinterpret_cast<uintptr_t>(&value);

    reg.id = KVM_REG_ARM64 | KVM_REG_SIZE_U64 | KVM_REG_ARM_CORE | KVM_REG_ARM_CORE_REG(regs.pc);
    value = entry;
    orc_syscall(ioctl(cpu, KVM_SET_ONE_REG, &reg));

    reg.id = KVM_REG_ARM64 | KVM_REG_SIZE_U64 | KVM_REG_ARM_CORE | KVM_REG_ARM_CORE_REG(sp_el1);
    value = 2 * megabyte;
    orc_syscall(ioctl(cpu, KVM_SET_ONE_REG, &reg));
#endif

#ifdef __x86_64__
    (void) entry;
#endif

#if 0
    struct kvm_regs regs = {};
    orc_syscall(ioctl(cpu, KVM_GET_REGS, &regs));
    std::cout << std::hex;
    for (size_t i(0); i != 34; ++i)
        std::cout << regs.regs.regs[i] << std::endl;
    orc_syscall(ioctl(cpu, KVM_SET_REGS, &regs));
#endif

    const auto buffer(reinterpret_cast<char *>(memory + megabyte));

    for (;;) {
#ifdef __aarch64__
        reg.id = KVM_REG_ARM64 | KVM_REG_SIZE_U64 | KVM_REG_ARM_CORE | KVM_REG_ARM_CORE_REG(regs.pc);
        orc_syscall(ioctl(cpu, KVM_GET_ONE_REG, &reg));
        std::cerr << std::hex << "KVM_RUN(0x" << value << ")" << std::endl;
#endif

        //__asm__ volatile ("dc civac, %0" : : "r" (buffer) : "memory");
        orc_syscall(ioctl(cpu, KVM_RUN, nullptr), EINTR);
        switch (run->exit_reason) {
            case KVM_EXIT_INTR:
                std::cout << "INTR" << std::endl;
                break;

            case KVM_EXIT_MMIO: {
                orc_assert_(run->mmio.phys_addr == 0x10000000, "mmio: 0x" << std::hex << run->mmio.phys_addr);
                orc_assert(run->mmio.is_write);
                orc_assert(run->mmio.len == sizeof(uintptr_t));
                switch (const auto command = *reinterpret_cast<const uintptr_t *>(run->mmio.data)) {
                    case 2: {
                        std::cout << buffer << std::flush;
                    } break;
                    default:
                        std::cout << "MMIO 0x" << std::hex << command << std::endl;
                    break;
                }
            } break;

            default: orc_insist(false);
        }
    }

    return 0;
}

}
// NOLINTEND(cppcoreguidelines-pro-type-vararg)
