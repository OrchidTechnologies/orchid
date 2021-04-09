#!/bin/bash
rm -rf out-dkr
exec docker run -i --rm --name orchid-env -v "$(dirname "${PWD}"):/mnt" ubuntu:bionic \
    /mnt/env/setup-dkr.sh make -C "${PWD##*/}" debug=crossndk output=out-dkr "$@"
