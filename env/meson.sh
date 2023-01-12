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

cfg="${curdir}/${output}/${arch}/meson.cfg"
echo "${wflags[@]}" >"${curdir}/${output}/${arch}/meson.cfg"
cfg=(--config "${cfg}")

function args() {
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
c = [$(args "${cc[@]}" "${cfg[@]}")]
cpp = [$(args "${cxx[@]}" "${cfg[@]}")]
objc = [$(args "${objc[@]}" "${cfg[@]}")]
ld = 'ld'
ar = '${ar}'
strip = '${strip}'
windres = '${windres}'
pkgconfig = '${curdir}/env/pkg-config.sh'

[properties]
needs_exe_wrapper = true
c_args = [$(args "${cflags[@]}")]
cpp_args = [$(args "${cflags[@]}" "${xflags[@]}")]
objc_args = [$(args "${cflags[@]}")]
c_link_args = [$(args "${lflags[@]}")]
cpp_link_args = [$(args "${lflags[@]}")]
objc_link_args = [$(args "${lflags[@]}")]
$(for mflag in ${mflags[@]}; do
    echo "${mflag%%=*} = ${mflag#*=}"
done)
EOF

if diff "${output}/${arch}"/meson.{new,txt} &>/dev/null; then
    rm -f "${output}/${arch}"/meson.new
else
    mv -f "${output}/${arch}"/meson.{new,txt}
fi
