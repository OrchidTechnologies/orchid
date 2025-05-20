#!/bin/bash
set -e
mkdir -p out

function build() {
    binary=$1
    shift

    object=()
    for source in "$@"; do
        output=${source%%.c}
        output=out/${output##*/}.o
        echo $source
        ./risc0.sh clang -std=c23 -c -o "${output}" "${source}" "${cflags[@]}"
        object+=("${output}")
    done

    ./risc0.sh clang++ -std=c++23 -o out/"${binary}" "${binary}".cpp "${cflags[@]}" "${object[@]}"
}


cflags=()
cflags+=(-Iextra)

cflags+=(-DPOLY1305_16BIT)

cflags+=(-Itrezor-firmware/crypto/chacha20poly1305)

build chacha trezor-firmware/crypto/chacha20poly1305/{chacha20poly1305,chacha_merged,poly1305-donna,rfc7539}.c


cflags=()
cflags+=(-Iextra)

cflags+=(-DSECP256K1_STATIC)

cflags+=(-DENABLE_MODULE_RECOVERY)
cflags+=(-DENABLE_MODULE_ECDH)

cflags+=(-DECMULT_WINDOW_SIZE=15)
cflags+=(-DECMULT_GEN_PREC_BITS=4)

cflags+=(-Isecp256k1/include)

build derive secp256k1/src/{secp256k1,precomputed_ecmult,precomputed_ecmult_gen}.c


cflags=()

build rehead
build stated

#build entire
build single

build update
