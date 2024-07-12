#!/bin/bash

source "$(dirname "$0")/env.sh"

if [ -f "README.md" ];
then
    # Back up the generated README.md in case it was edited by mistake.
    back="/tmp/README.md.$$"
    echo "backing up README.md to $back"
    cp README.md "$back"
fi

echo "Building README.md"

# examples
tmp=/tmp/readme.$$
sed -n '/# START_EXAMPLES/,/# END_EXAMPLES/p' examples/examples.sh | sed '/# START_EXAMPLES/d; /# END_EXAMPLES/d' > $tmp
sed "/INSERT_EXAMPLES/r $tmp" README-in.md | sed '/INSERT_EXAMPLES/d' > README.md

# usage
sed "/INSERT_USAGE/r docs/usage.sh" README.md | sed '/INSERT_USAGE/d' > out.md
mv out.md README.md

rm $tmp

echo "Don't forget to rebuild the CLI docs on changes."
