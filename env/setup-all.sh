#!/bin/bash
set -e
~/.cargo/bin/rustup update
exec env/setup-git.sh
