#!/bin/bash
set -e

rm -rf app-flutter
mkdir app-flutter
cd app-flutter

ln -s ../app-shared shared
ln -s shared/flutter
ln -s shared/gui/in_app_purchase

ln -s shared/gui/pubspec.yaml
ln -s shared/gui/lib
ln -s shared/gui/assets

ln -s ../app-flutter.mk makefile

flutter=flutter/bin/flutter

"${flutter}" create -i objc -a java --no-pub --project-name orchid .
rm -f README.md

"${flutter}" build apk
"${flutter}" build macos
"${flutter}" build ios
