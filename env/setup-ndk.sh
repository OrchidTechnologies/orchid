#!/bin/bash
set -e
set -o pipefail
echo y | "${ANDROID_HOME}"/cmdline-tools/latest/bin/sdkmanager "build-tools;29.0.2" "ndk;26.2.11394342" "platforms;android-33" >/dev/null
