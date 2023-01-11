#!/bin/bash
rm -rf out-dkr
exec docker run --platform linux/amd64 -i --rm --name orchid-env -v "$(dirname "${PWD}"):/mnt" ubuntu:focal \
    /mnt/env/setup-dkr.sh make -C "${PWD##*/}" debug=crossndk output=out-dkr "$@"
