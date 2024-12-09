#!/bin/sh
set -euo pipefail

base=$(dirname "$(realpath "$0")")
cd "$base" || exit

# if the tsc command is not installed tell the user to install typescript
if ! [ -x "$(command -v tsc)" ]; then
  echo 'Error: Typescript is not installed. Install with "npm -g install typescript"' >&2
  exit 1
fi

src="lib/chat/scripting"
ext_src="$src/extensions"

# Compile the scripting api typescript to js
mkdir -p ./web/lib
tsc --outFile ./web/lib/extensions/chat.js $src/chat_scripting_api.ts

# Build extensions
cd $ext_src || exit
for file in *.ts; do
  echo "Building extension $file"
  # rename the file to js
  jsfile=$(echo $file | sed 's/\.ts/\.js/')
  tsc --outFile "$jsfile" "$file"
  mv "$jsfile" "$base/web/lib/extensions/"
done

# Create a declaration file for development time use
#tsc $SRC/chat_scripting_api.ts --declaration --emitDeclarationOnly --outDir $SRC

