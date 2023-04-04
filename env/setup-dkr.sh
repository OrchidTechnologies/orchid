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
    useradd --badnames -oM -u "${uid}" -d "${HOME}" user
    apt-get -y install sudo
    echo 'user ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers
    chmod 755 ~
    chown -R "${uid}" ~
    exec sudo -u "#${uid}" "$@"
fi
