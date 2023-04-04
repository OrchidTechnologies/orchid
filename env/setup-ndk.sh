#!/bin/bash
set -e
set -o pipefail
echo y | "${ANDROID_HOME}"/cmdline-tools/latest/bin/sdkmanager "build-tools;29.0.2" "ndk;25.2.9519653" "platforms;android-33" >/dev/null
