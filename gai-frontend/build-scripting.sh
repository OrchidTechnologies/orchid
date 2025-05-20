#!/bin/sh
set -euo pipefail

base=$(dirname "$(realpath "$0")")
cd "$base" || exit

# Check for required tools
if ! [ -x "$(command -v tsc)" ]; then
    echo 'Error: TypeScript is not installed. Install with "npm -g install typescript"' >&2
    exit 1
fi

if ! [ -x "$(command -v rollup)" ]; then
    echo 'Error: Rollup is not installed. Install with "npm -g install rollup"' >&2
    exit 1
fi

src="lib/chat/scripting"
ext_src="$src/extensions"

# Ensure output directory exists
mkdir -p ./web/lib/extensions

# First compile the API
tsc --outFile ./web/lib/extensions/chat.js $src/chat_scripting_api.ts

# Build extensions
cd $ext_src || exit
for dir in */; do
    if [ -d "$dir" ]; then
        dir=${dir%/}  # Remove trailing slash
        echo "Building extension in $dir"
        cd "$dir" || exit
        
        # Clean up any previous build artifacts
        rm -rf dist
        mkdir -p dist
        
        echo "Compiling TypeScript files in $dir..."
        tsc --project tsconfig.json --outDir dist --listEmittedFiles
        
        echo "Checking for compiled output..."
        if [ ! -f "dist/extensions/asi/main.js" ]; then
            echo "TypeScript compilation did not produce main.js"
            echo "Contents of dist directory:"
            ls -R dist/
            exit 1
        fi
        
        echo "Bundling with Rollup..."
        rollup dist/extensions/asi/main.js --file "$base/web/lib/extensions/$dir.js" --format iife --name "asi" --extend
        
        # Cleanup
        rm -rf dist
        cd ..
    fi
done

# For single file extensions
for file in *.ts; do
    if [ -f "$file" ]; then
        echo "Building single file extension $file"
        jsfile="${file%.ts}.js"
        tsc --target es2020 "$file"
        mv "$jsfile" "$base/web/lib/extensions/"
    fi
done
