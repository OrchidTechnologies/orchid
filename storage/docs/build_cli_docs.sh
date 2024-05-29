#!/bin/bash

# Generate the CLI docs from help strings.

source "$(dirname "$0")/env.sh"
DOC="cli_docs.md"


if [ -f "$DOC" ];
then
    backup="/tmp/${DOC}.$$"
    echo "backing up $DOC to $backup"
    cp $DOC "$backup"
fi

tmp="/tmp/tmp_cli_docs.$$"
cp cli_docs-in.md "$DOC"

# storage cli
storage.sh docs > $tmp
sed "/INSERT_STORAGE_DOCS/r $tmp" "$DOC" | sed '/INSERT_STORAGE_DOCS/d' > out.md
mv out.md "$DOC"

# server cli
server.sh --help > $tmp
sed "/INSERT_SERVER_DOCS/r $tmp" "$DOC" | sed '/INSERT_SERVER_DOCS/d' > out.md
mv out.md "$DOC"

# providers cli
providers.sh --help > $tmp
sed "/INSERT_PROVIDERS_DOCS/r $tmp" "$DOC" | sed '/INSERT_PROVIDERS_DOCS/d' > out.md
mv out.md "$DOC"

# monitor cli
monitor.sh --help > $tmp
sed "/INSERT_MONITOR_DOCS/r $tmp" "$DOC" | sed '/INSERT_MONITOR_DOCS/d' > out.md
mv out.md "$DOC"

rm $tmp

