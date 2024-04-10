#!/bin/bash
set -e

if [[ $(id -u) -eq 0 ]]; then
    sudo=()
else
    sudo=(sudo -EH)
fi

. /etc/os-release
"${sudo[@]}" "env/lnx-${ID}.sh"

env/setup-all.sh
