#!/bin/bash
source "$(dirname "$0")/../env.sh"
python "$STRHOME/storage/storage_cli.py" "$@"
