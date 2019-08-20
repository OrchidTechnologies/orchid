#!/bin/bash
set -e
exec 1>&2

output=${1}
curdir=${2}
msys=${3}
mfam=${4}
ar=${5}
strip=${6}
cycc=${7}
cycp=${8}
cyco=${9}
qflags=${10}
wflags=${11}
shift 11

if [[ $# -ne 0 ]]; then
    exit 1
fi

cycc=(${cycc})
cycp=(${cycp})
cyco=(${cyco})

qflags=(${qflags})
wflags=(${wflags})

mkdir -p "${output}"

cflags=("${qflags[@]}")
cflags+=(-I"${curdir}/${output}/usr/include")

lflags=("${wflags[@]}")
lflags+=(-L"${curdir}/${output}/usr/lib")

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

cat >"${output}"/meson.new <<EOF
[host_machine]
system = '${msys}'
cpu_family = '${mfam}'
cpu = '${mfam}'
endian = 'little'

[properties]
c_args = [$(args "${cycc[@]}" "${cflags[@]}")]
cpp_args = [$(args "${cycp[@]}" "${cflags[@]}")]
objc_args = [$(args "${cyco[@]}" "${cflags[@]}")]
c_link_args = [$(args "${cycc[@]}" "${lflags[@]}")]
cpp_link_args = [$(args "${cycp[@]}" "${lflags[@]}")]
objc_link_args = [$(args "${cyco[@]}" "${lflags[@]}")]

[binaries]
c = '${cycc[0]}'
cpp = '${cycp[0]}'
objc = '${cyco[0]}'
ar = '${ar}'
strip = '${strip}'
pkgconfig = '${curdir}/env/pkg-config'
EOF

if diff "${output}"/meson.{new,txt} &>/dev/null; then
    rm -f "${output}"/meson.new
else
    mv -f "${output}"/meson.{new,txt}
fi
