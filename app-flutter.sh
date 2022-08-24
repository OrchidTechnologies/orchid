#!/bin/bash
set -e

rm -rf app-flutter
mkdir app-flutter
cd app-flutter

ln -s ../app-shared shared
ln -s ../app-flutter.mk makefile
ln -s ../gui-"$1" gui
ln -s ../env env

ln -s gui/pubspec.yaml
ln -s gui/lib
ln -s gui/l10n.yaml
ln -s gui/assets
ln -s gui/screenshots

ln -s shared/flutter-desktop-embedding

make create
