#!/bin/bash
set -e
set -o pipefail
cd "$(dirname "$0")/.."

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y install clang curl git-core software-properties-common sudo unzip

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0xB1998361219BD9C9
apt-add-repository "deb http://repos.azul.com/azure-only/zulu/apt stable main"
apt-get -y install zulu-8-azure-jdk='*'
export JAVA_HOME=/usr/lib/jvm/zulu-8-azure-amd64

curl -o android-sdk.zip https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
mkdir -p /usr/local/lib/android
unzip -d /usr/local/lib/android/sdk android-sdk.zip
rm -f android-sdk.zip
echo y | /usr/local/lib/android/sdk/tools/bin/sdkmanager "ndk;21.0.6113669" >/dev/null

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain=stable --profile=minimal

env/setup-lnx.sh
"$@"
