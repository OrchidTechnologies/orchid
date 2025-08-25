#!/bin/sh
set -euxo pipefail

FLUTTER="${FLUTTER:-$FLUTTER_STABLE}"; $FLUTTER --version | grep -i channel
#FLUTTER="$FLUTTER_STABLE"; $FLUTTER --version | grep -i channel
base=$(dirname "$0"); cd $base

rm -rf build/

# --web-rendered is obsolete in 3.29.  Now defaults to canvaskit.
$FLUTTER build web

cp web/page.html build/web/

