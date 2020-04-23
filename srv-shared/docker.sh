#!/bin/bash
rm -rf out-dkr
exec docker run -i --rm --name srv-orchid -v "$(dirname "${PWD}"):/mnt" ubuntu:bionic \
    /mnt/env/setup-dkr.sh make -C srv-shared -j3 debug=crossndk output=out-dkr
