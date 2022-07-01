#!/bin/bash
set -e
set -o pipefail

# XXX: https://github.com/actions/virtual-environments/issues/2689
if test -L "${ANDROID_HOME}"/ndk-bundle; then
    rm -f "${ANDROID_HOME}"/ndk-bundle
else
    "${ANDROID_HOME}"/tools/bin/sdkmanager --uninstall "ndk-bundle" >/dev/null
fi

echo y | "${ANDROID_HOME}"/tools/bin/sdkmanager "build-tools;29.0.2" "ndk;24.0.8215888" "platforms;android-30" >/dev/null

# XXX: this is really *seriously* wrong, but GitHub is going out of their way to set ANDROID_NDK_HOME to their bogus path
# XXX: the correct fix here is for GitHub to stop setting that at all; barring that, I need to un-set it at the top level
ln -s ndk/24.0.8215888 "${ANDROID_HOME}"/ndk-bundle
