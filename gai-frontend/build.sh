#!/bin/bash
set -euxo pipefail

# Build the scripting extensions
sh build-scripting.sh

# Set default mode to prod if not specified
MODE=${1:-prod}

# Select and export providers based on mode
if [ "$MODE" = "test" ]; then
    if [ -z "$ORCHID_GENAI_FRONTEND_PROVIDERS_TEST" ]; then
        echo "Error: ORCHID_GENAI_FRONTEND_PROVIDERS_TEST environment variable not set"
        exit 1
    fi
    export PROVIDERS=$(echo "$ORCHID_GENAI_FRONTEND_PROVIDERS_TEST" | tr -d '\n')
elif [ "$MODE" = "local" ]; then
    # Use a default local configuration with both inference and tool providers
    # Note: For the Tool Node Protocol, endpoints should match your local server setup
    # Convert multi-line JSON to a single line for the dart-define parameter
    export PROVIDERS=$(echo "$ORCHID_GENAI_FRONTEND_PROVIDERS_LOCAL" | tr -d '\n')
    echo "Using local development configuration with localhost endpoints"
else
    if [ -z "$ORCHID_GENAI_FRONTEND_PROVIDERS_PROD" ]; then
        echo "Error: ORCHID_GENAI_FRONTEND_PROVIDERS_PROD environment variable not set"
        exit 1
    fi
    export PROVIDERS=$(echo "$ORCHID_GENAI_FRONTEND_PROVIDERS_PROD" | tr -d '\n')
fi

# Use an array to properly handle the arguments with quotes
echo "Building with providers: $PROVIDERS"
flutter build web --dart-define=PROVIDERS="$PROVIDERS"

# Clean up
unset PROVIDERS

# Exit with flutter's exit code
exit $?
