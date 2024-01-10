#!/bin/bash
source "$(dirname "$0")/env.sh"
python "$STRHOME/server/providers_cli.py" "$@"
