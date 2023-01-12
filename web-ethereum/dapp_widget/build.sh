#!/bin/sh
set -euxo pipefail

#FLUTTER="${FLUTTER:-$FLUTTER_STABLE}"; $FLUTTER --version | grep -i channel
FLUTTER="$FLUTTER_STABLE"; $FLUTTER --version | grep -i channel
base=$(dirname "$0"); cd $base

rm -rf build/

$FLUTTER build web --web-renderer canvaskit
#flutter build web --web-renderer html

cp web/page.html build/web/

