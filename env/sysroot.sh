#!/bin/bash
set -e
set -o pipefail

sysroot=$1
shift 1

rm -rf "${sysroot}"
mkdir -p "${sysroot}"
cd "${sysroot}"

# XXX: this currently doesn't work as non-root (and fakechroot didn't work right)
if [[ $(uname -s) == Linux && $(id -u) == 0 ]] && which skopeo 2>/dev/null; then
    skopeo copy docker://centos:6 dir:.
    jq -r '.layers [] .digest' manifest.json | while IFS=: read -r alg dig; do fakeroot tar -zxvf "${dig}"; done
    # XXX: this doesn't work on GitHub CI due to some kind of systemd-resolved nonsense
    # cp -af /etc/resolv.conf etc
    echo 'nameserver 1.0.0.1' >etc/resolv.conf
    chroot . yum -y install gcc-c++
else
    name=orchid

    function clean() {
        docker container rm "${name}"
    }

    clean 2>/dev/null || true

    docker run -i --name "${name}" centos:6 yum -y install gcc-c++
    trap clean EXIT

    docker export "${name}" | fakeroot tar \
        --exclude dev \
        --exclude etc \
        --exclude usr/lib/locale \
        --exclude usr/lib/python2.6 \
        --exclude usr/lib64/python2.6 \
        --exclude usr/share \
        --exclude var \
    -xmvf-
fi

find . -type d ! -perm 755 -exec chmod 755 {} +

find . -lname '/*' -print0 | while read -r -d $'\0' link; do
    temp=(${link//\// })
    temp=${temp[@]//*/..}
    temp=${temp// /\/}
    temp=${temp#../../}
    temp=${temp}$(readlink "${link}")
    rm -f "${link}"
    ln -svf "${temp}" "${link}"
done
