#!/bin/bash

# Cycc/Cympile - Shared Build Scripts for Make
# Copyright (C) 2013-2019  Jay Freeman (saurik)

# Zero Clause BSD license {{{
#
# Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# }}}


set -o pipefail

width=4

describe=$(git describe --tags --match="v*" "$@" 2>/dev/null)
monotonic=$(git log -1 --pretty=format:%ct)

commit=$(git rev-parse HEAD)
decimal=$(echo "obase=10;ibase=16;$(echo "${commit}" | cut -c "1-${width}" | tr '[:lower:]' '[:upper:]')" | bc)

package=$(echo "${describe}" | sed -e 's@-\([^-]*\)-\([^-]*\)$@.p\1.\2@;s@^v@@;s@%@~@g')
version=$(echo "${describe}" | sed -e 's@^v@@;s@-.*@@')

revision=$(echo "obase=2;${monotonic} * 2^(4*${width}) + ${decimal}" | BC_LINE_LENGTH=64 bc)

if git status --ignore-submodules=dirty -s | cut -c 1-2 | grep M >/dev/null; then
    package+='.x'
    revision+=1
else
    revision+=0
fi

length=${#revision}
revision=$(echo "ibase=2;${revision:0:length-21-21}" | bc).$(echo "ibase=2;${revision:length-21-21:21}" | bc).$(echo "ibase=2;${revision:length-21:21}" | bc)

echo "${monotonic}" "${revision}" "${package}" "${version}"
