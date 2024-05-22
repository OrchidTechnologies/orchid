#!/bin/bash
# Source this file into your shell
export STRHOME=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $STRHOME/venv/bin/activate
export PYTHONPATH="$STRHOME"
export PATH=$PATH:"$STRHOME"
