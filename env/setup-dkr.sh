#!/bin/bash
set -e
cd "$(dirname "$0")/.."

env/setup-lnx.sh

curl -o android-sdk.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
unzip android-sdk.zip
rm -f android-sdk.zip
mkdir -p /usr/local/lib/android/sdk/cmdline-tools
mv cmdline-tools /usr/local/lib/android/sdk/cmdline-tools/latest
export ANDROID_HOME=/usr/local/lib/android/sdk

env/setup-ndk.sh

uid=$(stat -c %u /mnt)
if [[ ${uid} -eq 0 ]]; then
    exec "$@"
else
    # newer versions of sudo and/or Ubuntu disallow using sudo to become a user that doesn't exist? :/
    useradd --badnames -oM -u "${uid}" -d "${HOME}" user # XXX: if I'm doing this can't I just use su?
    apt-get -y install sudo
    chmod 755 ~
    chown -R "${uid}" ~
    exec sudo -u "#${uid}" "$@"
fi
