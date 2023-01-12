#!/bin/sh
set -euxo pipefail

#FLUTTER="${FLUTTER:-$FLUTTER_STABLE}"; $FLUTTER --version | grep -i channel
FLUTTER="$FLUTTER_STABLE"; $FLUTTER --version | grep -i channel
base=$(dirname "$0"); cd $base

rm -rf build

#_profile="--profile"
#$FLUTTER build web --web-renderer canvaskit --dart-define mock=true
commit=$(git rev-parse --short HEAD)
$FLUTTER build web ${_profile:-} --web-renderer canvaskit --dart-define build_commit=$commit

# move js to hash named file
uuid=$(uuidgen)
gsed -i "s/main.dart.js/${uuid}.main.dart.js/g" build/web/index.html
mv build/web/main.dart.js "build/web/${uuid}.main.dart.js"

