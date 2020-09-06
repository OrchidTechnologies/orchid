#!/bin/bash
exec curl -u "$1" --data-binary @"$4" \
    -H "accept: application/vnd.github.v3+json" \
    -H "content-type: $5" \
"https://uploads.github.com/repos/$2/releases/$3/assets?name=$6" | jq
