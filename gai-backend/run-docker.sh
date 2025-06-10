#!/bin/bash

set -e

file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"

    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

file_env "ORCHID_GENAI_ADDR"
file_env "ORCHID_GENAI_PORT"
file_env "ORCHID_GENAI_REDIS_URL"
file_env "ORCHID_GENAI_RECIPIENT_KEY"

while true
do
  python server.py --config config.json;
  sleep 1;
done

