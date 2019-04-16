#!/bin/bash
set -e
docker run --rm -i -v "${PWD}/../env/autogen_.sh:/init" -v "${PWD}:/mnt" ubuntu:bionic /init
