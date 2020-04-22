#!/bin/bash
name=orchid
docker rm -f "env-${name}" &>/dev/null || true
docker run -i --name "env-${name}" -v /var/run/docker.sock:/var/run/docker.sock -v "${PWD}:/mnt" ubuntu:bionic /mnt/env/setup-dkr.sh "$@"
docker start "env-${name}"
