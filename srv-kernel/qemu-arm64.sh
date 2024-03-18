#!/bin/bash
set -e

(cd qemu && make -kj12)
make -kj12 target=lnx machine=arm64

kernel=out-lnx-26.2/arm64/kernel

qemu/build/qemu-system-aarch64 -kernel "${kernel}" \
    -M virt -cpu cortex-a53 \
    -m 128m -nic none -nodefaults -display none -nic none \
    -nographic -monitor unix:qemu.sock,server,nowait \
    -no-user-config -d in_asm,op,mmu,cpu_reset,int,cpu
