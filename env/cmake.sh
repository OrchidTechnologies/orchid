#!/bin/bash
set -e
exec 1>&2

arch=${1}
output=${2}
curdir=${3}
meson=${4}
ar=${5}
strip=${6}
windres=${7}
cc=${8}
cxx=${9}
objc=${10}
qflags=${11}
wflags=${12}
xflags=${13}
mflags=${14}
shift 14

if [[ $# -ne 0 ]]; then
    exit 1
fi

meson=(${meson})

cc=(${cc})
cxx=(${cxx})
objc=(${objc})

qflags=(${qflags})
wflags=(${wflags})
xflags=(${xflags})

mkdir -p "${output}/${arch}"

cflags=(-I"${curdir}/${output}/${arch}/usr/include")
lflags=(-L"${curdir}/${output}/${arch}/usr/lib")

cflags+=("${qflags[@]}")

cfg="${curdir}/${output}/${arch}/cmake.cfg"
echo "${wflags[@]}" >"${curdir}/${output}/${arch}/cmake.cfg"
cfg=(--config "${cfg}")


# XXX: I need to set CMAKE_SYSTEM_VERSION
cat >"${output}/${arch}"/cmake.new <<EOF
set(CMAKE_SYSTEM_NAME ${meson[0]})
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR "${meson[1]}")

set(CMAKE_ASM_COMPILER ${cc[@]} ${cfg[@]})
set(CMAKE_C_COMPILER ${cc[@]} ${cfg[@]})
set(CMAKE_CXX_COMPILER ${cxx[@]} ${cfg[@]})

set(CMAKE_ASM_FLAGS "\${CMAKE_ASM_FLAGS} ${cflags[@]}" CACHE STRING "asm flags")
set(CMAKE_C_FLAGS "\${CMAKE_C_FLAGS} ${cflags[@]}" CACHE STRING "c flags")
set(CMAKE_CXX_FLAGS "\${CMAKE_CXX_FLAGS} ${cflags[@]} ${xflags[@]}" CACHE STRING "c++ flags")
EOF

if diff "${output}/${arch}"/cmake.{new,txt} &>/dev/null; then
    rm -f "${output}/${arch}"/cmake.new
else
    mv -f "${output}/${arch}"/cmake.{new,txt}
fi
