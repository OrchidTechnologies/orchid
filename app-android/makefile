# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2019  The Orchid Authors

# GNU Affero General Public License, Version 3 {{{ */
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# }}}


target := and
include env/target.mk

apk := build/outputs/apk/release/app-android-release-unsigned.apk

.PHONY: all
all: $(output)/Orchid.apk

.PHONY: install
install: $(output)/Orchid.apk
	adb install -r $<

include vpn/target.mk

include env/output.mk

$(output)/armeabi-v7a/liborchid.so: $(object) $(linked)
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cycp) -shared $(wflags) -o $@ $^ $(lflags)

mode := release
assets := $(output)/assets/flutter_assets

include shared/flutter.mk

build/app%dill %flutter-plugins $(assets)/kernel_blob%bin src/main/java/io/flutter/plugins/GeneratedPluginRegistrant%java: $(shell find lib/ -name '*.dart') flutter/packages/flutter/pubspec%lock pubspec%lock
	rm -rf $(assets) $(output)/snapshot_blob.bin.d $(output)/snapshot_blob.bin.d.fingerprint
	@mkdir -p build $(output) $(assets)
	$(environ) flutter/bin/flutter --suppress-analytics --verbose build bundle --target-platform=android-arm --target=lib/main.dart --$(mode) --depfile="$(output)/snapshot_blob.bin.d" --asset-dir="$(assets)"

$(apk): $(shell find src/main/kotlin -name '*.kt') $(output)/armeabi-v7a/liborchid.so $(assets)/kernel_blob.bin src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java
	@gradle -Pandroid.debug.obsoleteApi=true assembleRelease --console verbose
	exit 0
	touch $@

debug.keystore:
	echo $$'android\nandroid\n\n\n' | keytool -genkey -v -keystore debug.keystore -alias androiddebugkey -dname "CN=Android Debug,O=Android,C=US" -validity 365 -keyalg RSA -keysize 2048

keystore := debug
keyalias := androiddebugkey
keyextra := 

verbose := 

$(output)/Orchid.apk: $(apk) $(keystore).keystore $(keyextra)
	cp -af $(apk) $(output)/signed.apk
	jarsigner -digestalg SHA1 -sigalg MD5withRSA $(if $(verbose),-verbose) -sigfile CERT -keystore $(keystore).keystore -storepass android -tsa http://timestamp.digicert.com/ $(output)/signed.apk $(keyalias)
	zipalign -f $(if $(verbose),-v) 4 $(output)/signed.apk $@
	@rm -rf $(output)/signed.apk
