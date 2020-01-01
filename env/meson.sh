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

cflags=("${qflags[@]}")
cflags+=(-I"${curdir}/${output}/${arch}/usr/include")

lflags=("${wflags[@]}")
lflags+=(-L"${curdir}/${output}/${arch}/usr/lib")

function args() {
    shift
    comma=false
    for arg in "$@"; do
        if ${comma}; then
            echo -n ", "
        else
            comma=true
        fi
        echo -n "'${arg}'"
    done
}

cat >"${output}/${arch}"/meson.new <<EOF
[host_machine]
system = '${meson[0]}'
cpu_family = '${meson[1]}'
cpu = '${meson[1]}'
endian = 'little'

[binaries]
c = '${cc[0]}'
cpp = '${cxx[0]}'
objc = '${objc[0]}'
ar = '${ar}'
strip = '${strip}'
windres = '${windres}'
pkgconfig = '${curdir}/env/pkg-config'

[properties]
c_args = [$(args "${cc[@]}" "${cflags[@]}")]
cpp_args = [$(args "${cxx[@]}" "${cflags[@]} ${xflags[@]}")]
objc_args = [$(args "${objc[@]}" "${cflags[@]}")]
c_link_args = [$(args "${cc[@]}" "${lflags[@]}")]
cpp_link_args = [$(args "${cxx[@]}" "${lflags[@]}")]
objc_link_args = [$(args "${objc[@]}" "${lflags[@]}")]
$(for mflag in ${mflags[@]}; do
    echo "${mflag%%=*} = ${mflag#*=}"
done)
EOF

if diff "${output}/${arch}"/meson.{new,txt} &>/dev/null; then
    rm -f "${output}/${arch}"/meson.new
else
    mv -f "${output}/${arch}"/meson.{new,txt}
fi
