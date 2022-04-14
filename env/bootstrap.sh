#!/bin/bash
name=orchid
docker rm -f "env-${name}" &>/dev/null || true
docker run -i --name "env-${name}" -v "${PWD}:/mnt" ubuntu:bionic /mnt/env/setup-dkr.sh "$(id -u)" "$@"
docker start "env-${name}"
