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

$(output)/jnilibs/$(alib)/liborchid.so: $(object) $(linked)
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cycp) -shared $(wflags) -o $@ $^ $(lflags)
	@ls -la $@

assets := $(output)/assets/flutter_assets

include shared/flutter.mk

ifneq ($(precompiled),)
$(output)/aot/app.so: $(dart)
	flutter/bin/flutter --suppress-analytics --verbose build aot -t lib/main.dart \
	    --target-platform=android-arm --$(mode) --output-dir=$(output)/aot

$(output)/jnilibs/$(alib)/libapp.so: $(output)/aot/app.so
	@mkdir -p $(dir $@)
	cp -f $< $@
endif

$(assets)/AssetManifest%json %flutter-plugins src/main/java/io/flutter/plugins/GeneratedPluginRegistrant%java: flutter/packages/flutter/pubspec%lock pubspec%lock $(dart)
	rm -rf $(assets) $(output)/snapshot_blob.bin.d $(output)/snapshot_blob.bin.d.fingerprint
	@mkdir -p build $(output) $(assets)
	flutter/bin/flutter --suppress-analytics --verbose build bundle -t lib/main.dart \
	    --depfile="$(output)/snapshot_blob.bin.d" --asset-dir="$(assets)" --output-dill="$(output)/build.dill" \
	    --target-platform=android-arm --$(mode) $(precompiled)

$(apk): $(shell find src/main/kotlin -name '*.kt') $(shell find src/main/java -name '*.java') $(shell find src/main/res) build.gradle src/main/AndroidManifest.xml $(output)/jnilibs/$(alib)/liborchid.so $(output)/jnilibs/$(alib)/libapp.so src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java
	@gradle -Pandroid.debug.obsoleteApi=true assembleRelease --console verbose --warning-mode all
	exit 0
	touch $@

../debug.keystore:
	echo $$'android\nandroid\n\n\n' | keytool -genkey -v -keystore $@ -alias androiddebugkey -dname "CN=Android Debug,O=Android,C=US" -validity 365 -keyalg RSA -keysize 2048

keystore := ../debug
keyalias := androiddebugkey
keyextra := 

verbose := 

zipalign := $(word 1,$(wildcard $(ANDROID_HOME)/build-tools/*/zipalign))
ifeq ($(zipalign),)
$(error unable to find zipalign)
endif

$(output)/Orchid.apk: $(apk) $(keystore).keystore $(keyextra)
	cp -af $(apk) $(output)/signed.apk
	jarsigner -digestalg SHA1 -sigalg MD5withRSA $(if $(verbose),-verbose) -sigfile CERT -keystore $(keystore).keystore -storepass android -tsa http://timestamp.digicert.com/ $(output)/signed.apk $(keyalias)
	$(zipalign) -f $(if $(verbose),-v) 4 $(output)/signed.apk $@
	@rm -rf $(output)/signed.apk
