#!/bin/bash

set -e

file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"

    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; 
    then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; 
    then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; 
    then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

file_env "ORCHID_GENAI_ADDR"
file_env "ORCHID_GENAI_PORT"
file_env "ORCHID_GENAI_REDIS_URL"
file_env "ORCHID_GENAI_RECIPIENT_KEY"
file_env "ORCHID_GENAI_BILLING"
file_env "ORCHID_GENAI_INFERENCE"

if [[ "$ORCHID_GENAI_BILLING" == "$ORCHID_GENAI_INFERENCE" ]] ;
then
    echo >&2 'error: both $ORCHID_GENAI_BILLING and $ORCHID_GENAI_INFERENCE are set (but are exclusive), or neither is set and one is required'
    exit 1
fi

if [[ "$ORCHID_GENAI_INFERENCE" == "true" ]] ;
then
    command="uvicorn inference_api:app --host 0.0.0.0 --port 8010;"
elif [[ "$ORCHID_GENAI_BILLING" == "true" ]]
then
    command="python server.py --config config.json"
else
    echo >&2 'Neither $ORCHID_GENAI_BILLING or $ORCHID_GENAI_INFERENCE are set to "true", and one is required to be set to "true"'
    exit 1
fi

while true
do
  eval $command;
  sleep 1;
done

