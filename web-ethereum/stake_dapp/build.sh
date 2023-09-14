#!/bin/sh
set -euxo pipefail

# Set the environment and build dir.
#FLUTTER="${FLUTTER:-$FLUTTER_STABLE}"; $FLUTTER --version | grep -i channel
FLUTTER="$FLUTTER_STABLE"; $FLUTTER --version | grep -i channel
base=$(dirname "$0") 
cd $base

# Clean
rm -rf build; mkdir -p build/web

# Create our patched flutter_web3 package if needed.
sh flutter_web3.sh

# Build the dapp
#_profile="--profile --dart-define=Dart2jsOptimization=O0"
#$FLUTTER build web --web-renderer canvaskit --dart-define mock=true
commit=$(git rev-parse --short HEAD)
$FLUTTER build web ${_profile:-} --web-renderer canvaskit --dart-define build_commit=$commit

# Move js to hash named file
uuid=$(uuidgen)
gsed -i "s/main.dart.js/${uuid}.main.dart.js/g" build/web/index.html
mv build/web/main.dart.js "build/web/${uuid}.main.dart.js"

