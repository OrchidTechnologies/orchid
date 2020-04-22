#!/bin/bash
exec ./docker.sh "$(git config --get remote.origin.url)" "$(git show-ref -s HEAD)"
