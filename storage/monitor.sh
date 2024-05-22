#!/bin/bash
source "$(dirname "$0")/env.sh"
python "$STRHOME/monitor/monitor_cli.py" "$@"
