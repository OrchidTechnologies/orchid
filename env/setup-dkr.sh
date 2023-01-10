#!/bin/bash
set -e
cd "$(dirname "$0")/.."

env/setup-lnx.sh

apt-get -y install software-properties-common
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9
apt-add-repository "deb http://repos.azul.com/azure-only/zulu/apt stable main"
apt-get -y install zulu-8-azure-jdk='*'
export JAVA_HOME=/usr/lib/jvm/zulu-8-azure-amd64

curl -o android-sdk.zip https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
mkdir -p /usr/local/lib/android
unzip -d /usr/local/lib/android/sdk android-sdk.zip
rm -f android-sdk.zip
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
