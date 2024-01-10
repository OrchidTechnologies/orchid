#!/bin/bash

source "$(dirname "$0")/env.sh"

back="/tmp/README.md.$$"
echo "backing up README.md to $back"
cp README.md "$back"

# examples
tmp=/tmp/readme.$$
sed -n '/# START_EXAMPLES/,/# END_EXAMPLES/p' examples/examples.sh | sed '/# START_EXAMPLES/d; /# END_EXAMPLES/d' > $tmp
sed "/INSERT_EXAMPLES/r $tmp" README-in.md | sed '/INSERT_EXAMPLES/d' > README.md

# usage
sed "/INSERT_USAGE/r docs/usage.sh" README.md | sed '/INSERT_USAGE/d' > out.md
mv out.md README.md

# storage cli
storage.sh docs > $tmp
sed "/INSERT_STORAGE_DOCS/r $tmp" README.md | sed '/INSERT_STORAGE_DOCS/d' > out.md
mv out.md README.md

# server cli
server.sh --help > $tmp
sed "/INSERT_SERVER_DOCS/r $tmp" README.md | sed '/INSERT_SERVER_DOCS/d' > out.md
mv out.md README.md

# providers cli
providers.sh --help > $tmp
sed "/INSERT_PROVIDERS_DOCS/r $tmp" README.md | sed '/INSERT_PROVIDERS_DOCS/d' > out.md
mv out.md README.md

# monitor cli
monitor.sh --help > $tmp
sed "/INSERT_MONITOR_DOCS/r $tmp" README.md | sed '/INSERT_MONITOR_DOCS/d' > out.md
mv out.md README.md

rm $tmp

