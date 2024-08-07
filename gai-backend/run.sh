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

file_env "ORCHID_GENAI_LLM_AUTH_KEY"
file_env "ORCHID_GENAI_RECIPIENT_KEY"
file_env "ORCHID_GENAI_LLM_URL"

while true
do
  python server.py;
  sleep 1;
done

