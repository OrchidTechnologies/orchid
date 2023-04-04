#!/bin/bash
set -e
"$@"
tar -czf /tmp/export.tgz -C / --one-file-system --exclude=./tmp .
