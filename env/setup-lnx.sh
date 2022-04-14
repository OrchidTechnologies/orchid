#!/bin/bash
set -e

if [[ $(id -u) -eq 0 ]]; then
    sudo=()
else
    sudo=(sudo -EH)
fi

"${sudo[@]}" env/setup-apt.sh

env/setup-all.sh
