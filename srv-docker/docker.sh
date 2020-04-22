#!/bin/bash
exec docker run -i --rm --name srv-docker -v /var/run/docker.sock:/var/run/docker.sock -v "$(dirname "${PWD}"):/mnt" ubuntu:bionic \
    /mnt/srv-docker/build.sh "$@"
