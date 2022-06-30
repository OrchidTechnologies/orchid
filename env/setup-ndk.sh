#!/bin/bash
set -e
set -o pipefail
echo y | "${ANDROID_HOME}"/tools/bin/sdkmanager "build-tools;29.0.2" "ndk;24.0.8215888" "platforms;android-30" >/dev/null
