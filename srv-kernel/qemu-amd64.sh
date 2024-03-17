#!/bin/bash
set -e

(cd qemu && make -kj12)
make -kj12 target=lnx machine=x86_64

kernel=out-lnx-26.2/x86_64/kernel

    #-M microvm,pit=off,pic=off,isa-serial=off,rtc=off \

qemu/build/qemu-system-x86_64 -kernel "${kernel}"  \
    -M microvm \
    -m 128m -nic none -nodefaults -display none -nic none \
    -nographic -monitor unix:qemu.sock,server,nowait \
    -no-user-config -d in_asm,op,mmu,cpu_reset,int,cpu

    #-chardev stdio,id=virtiocon0
    #-device virtio-serial-device
    #-device virtconsole,chardev=virtiocon0
    #-drive id=test,file=test.img,format=raw,if=none
    #-device virtio-blk-device,drive=test
    #-netdev tap,id=tap0,script=no,downscript=no
    #-device virtio-net-device,netdev=tap0
