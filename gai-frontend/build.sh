#!/bin/bash

# Set default mode to prod if not specified
MODE=${1:-prod}

# Select and export providers based on mode
if [ "$MODE" = "test" ]; then
    if [ -z "$ORCHID_GENAI_FRONTEND_PROVIDERS_TEST" ]; then
        echo "Error: ORCHID_GENAI_FRONTEND_PROVIDERS_TEST environment variable not set"
        exit 1
    fi
    export PROVIDERS="$ORCHID_GENAI_FRONTEND_PROVIDERS_TEST"
else
    if [ -z "$ORCHID_GENAI_FRONTEND_PROVIDERS_PROD" ]; then
        echo "Error: ORCHID_GENAI_FRONTEND_PROVIDERS_PROD environment variable not set"
        exit 1
    fi
    export PROVIDERS="$ORCHID_GENAI_FRONTEND_PROVIDERS_PROD"
fi

BUILD_CMD="flutter build web --dart-define=PROVIDERS='$PROVIDERS'"
echo "Executing: $BUILD_CMD"
eval "$BUILD_CMD"

# Clean up
unset PROVIDERS

# Exit with flutter's exit code
exit $?
