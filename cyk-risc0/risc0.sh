#!/bin/bash
clang=$1
shift 1
exec "${clang}" \
    -target riscv32-unknown-none -march=rv32im -mabi=ilp32 \
    -Wl,-z,max-page-size=1024 -Wl,-Ttext=0x00200800 \
    -ffreestanding -nostdlib -fno-exceptions \
    -Wno-dangling-else -Wno-invalid-noreturn \
    -Wno-vla-cxx-extension \
    -O3 -g0 -Wl,-s -fno-ident \
    -D_LIBCPP_HAS_NO_THREADS \
    "$@"
