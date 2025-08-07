#!/bin/bash
set -e
set -o pipefail

ndk=27.0.12077973

echo y | "${ANDROID_HOME}"/cmdline-tools/latest/bin/sdkmanager "ndk;${ndk}" "build-tools;34.0.0" "platforms;android-34" >/dev/null

export ANDROID_NDK_ROOT="${ANDROID_HOME}/ndk/${ndk}"

if [[ -n ${GITHUB_ENV} ]]; then
    echo "ANDROID_NDK_ROOT=${ANDROID_NDK_ROOT}" >>"${GITHUB_ENV}"
fi
