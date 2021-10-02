#!/bin/bash
set -e
security find-certificate -aZ "$@" | sed -e '/^SHA-1/!d;s/.* //'
