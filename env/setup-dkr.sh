#!/bin/bash
set -e
set -o pipefail
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
echo y | /usr/local/lib/android/sdk/tools/bin/sdkmanager "build-tools;30.0.2" "ndk;22.1.7171670" >/dev/null

"$@"
