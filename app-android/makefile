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
	adb install -d -r $<

$(call include,vpn/target.mk)

include env/output.mk

$(output)/jnilibs/%/liborchid.so: $(patsubst %,$(output)/$$*/%,$(object) $(linked))
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cxx/$*) -shared $(wflags) -o $@ $^ $(lflags)
	@ls -la $@

assets := $(output)/assets/flutter_assets

include shared/flutter.mk

ifneq ($(precompiled),)
$(output)/%/aot/app.so: $(dart)
	flutter/bin/flutter --suppress-analytics --verbose build aot -t lib/main.dart \
	    --target-platform=android-$(flutter/$*) --$(mode) --output-dir=$(dir $@)

$(output)/jnilibs/%/libapp.so: $(output)/%/aot/app.so
	@mkdir -p $(dir $@)
	cp -f $< $@
endif

jni := armeabi-v7a arm64-v8a
#jnis := $(subst $(space),$(comma),$(foreach arch,$(jni),android-$(flutter/$(arch))))

$(assets)/AssetManifest%json %flutter-plugins src/main/java/io/flutter/plugins/GeneratedPluginRegistrant%java: flutter/packages/flutter/pubspec.lock pubspec.lock pubspec.yaml $(dart)
	rm -rf $(assets) $(output)/snapshot_blob.bin.d $(output)/snapshot_blob.bin.d.fingerprint
	@mkdir -p build $(output) $(assets)
	flutter/bin/flutter --suppress-analytics --verbose build bundle -t lib/main.dart \
	    --depfile="$(output)/snapshot_blob.bin.d" --asset-dir="$(assets)" --output-dill="$(output)/build.dill" \
	    --target-platform=android-arm --$(mode) $(precompiled)

define _
$(output)/flutter.jar: flutter/bin/cache/artifacts/engine/android-$(flutter/$(1))-release/flutter.jar
flutter/bin/cache/artifacts/engine/android-$(flutter/$(1))-release/flutter.jar: flutter/packages/flutter/pubspec.lock
endef
$(foreach arch,$(jni),$(eval $(call _,$(arch))))

jni := $(foreach arch,$(jni),$(foreach jni,orchid flutter app,$(output)/jnilibs/$(arch)/lib$(jni).so))

$(output)/jnilibs/%/libflutter.so: flutter/bin/cache/artifacts/engine/android-$$(flutter/$$*)-release/flutter.jar
	@mkdir -p $(dir $@)
	unzip -p $< lib/$*/libflutter.so >$@

$(apk): $(shell find src/main/kotlin -name '*.kt') $(shell find src/main/java -name '*.java') $(shell find src/main/res) build.gradle src/main/AndroidManifest.xml $(jni) src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java $(assets)/AssetManifest.json $(output)/flutter.jar
	@gradle -Pandroid.debug.obsoleteApi=true assembleRelease --console verbose --warning-mode all \
	    -PorcMonotonic='$(monotonic)' -PorcRevision='$(revision)' -PorcPackage='$(package)' -PorcVersion='$(version)' \
	    -PflutterJar=flutter/bin/cache/artifacts/engine/android-arm-release/flutter.jar
	exit 0
	touch $@

ifeq ($(keystore),)
keystore := ../debug androiddebugkey

$(word 1,$(keystore)).keystore:
	echo $$'android\nandroid\n\n\n' | keytool -genkey -v -keystore $@ -alias $(word 2,$(keystore)) -dname "CN=Android Debug,O=Android,C=US" -validity 365 -keyalg RSA -keysize 2048
endif

verbose := 

zipalign := 
ifneq ($(ANDROID_HOME),)
zipalign := $(firstword $(wildcard $(ANDROID_HOME)/build-tools/*/zipalign))
endif
ifeq ($(zipalign),)
zipalign := $(shell which zipalign)
endif
ifeq ($(zipalign),)
$(error unable to find zipalign)
endif

$(output)/Orchid.apk: $(apk) $(word 1,$(keystore)).keystore
	cp -af $(apk) $(output)/signed.apk
	jarsigner -digestalg SHA1 -sigalg MD5withRSA $(if $(verbose),-verbose) -sigfile CERT -keystore $(word 1,$(keystore)).keystore -storepass android -tsa http://timestamp.digicert.com/ $(output)/signed.apk $(word 2,$(keystore))
	$(zipalign) -f $(if $(verbose),-v) 4 $(output)/signed.apk $@
	@rm -rf $(output)/signed.apk
