#!/bin/bash
source "$(dirname "$0")/env.sh"

# if "--repository" is not specified, use the default repository
if [[ "$*" != *"--repository"* ]]; then
    echo "Using default repository: $STRHOME/repository"
    set -- "$@" --repository "$STRHOME/repository"
fi

python "$STRHOME/server/server_cli.py" "$@"
