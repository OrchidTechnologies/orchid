# Orchid - WebRTC P2P VPN Market (on Ethereum)
# Copyright (C) 2017-2020  The Orchid Authors

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

cflags += -DGUI_$(gui)

.PHONY: all
all: $(output)/$(name).apk

.PHONY: install
install: $(output)/$(name).apk
	adb install -d -r $<

.PHONY: attach
attach:
	cd $(pwd/gui) && $(flutter) attach

.PHONY: upload
upload: $(output)/$(name).apk
	env/upload-apk.py $(domain).$(name) $<

$(call include,vpn/target.mk)
$(call include,shared/target-and.mk)

apk := $(output)/build/outputs/apk/$(mode)/app-android-$(if $(filter noaot,$(debug)),debug,release).apk

include env/output.mk

$(output)/jnilibs/%/liborchid.so: $(patsubst %,$(output)/$$*/%,$(object) $(linked))
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cxx) $(more/$*) -shared $(wflags) -o $@ $^ $(lflags)
	@openssl sha256 -r $@
	@ls -la $@

$(output)/jnilibs/%/libapp.so: $(output)/flutter/%/app.so
	@mkdir -p $(dir $@)
	cp -f $< $@

$(output)/assets/flutter_assets/AssetManifest%json: $(output)/flutter/flutter_assets/AssetManifest.json
	@mkdir -p $(dir $@)
	rsync -a --delete $(dir $<) $(dir $@)

$(pwd/flutter)/bin/cache/artifacts/engine/android-%$(engine)/flutter.jar: $(pwd/flutter)/packages/flutter/pubspec.lock
	@

temp := $(foreach arch,$(jni),$(foreach base,orchid flutter $(if $(filter noaot,$(debug)),,app),$(output)/jnilibs/$(arch)/lib$(base).so))

$(output)/jnilibs/%/libflutter.so: $(pwd/flutter)/bin/cache/artifacts/engine/$$(flutter/$$*)$(engine)/flutter.jar
	@mkdir -p $(dir $@)
	unzip -p $< lib/$*/libflutter.so >$@

ifeq ($(keystore),)
keystore := ../debug androiddebugkey android

$(word 1,$(keystore)).keystore:
	echo $$'$(word 3,$(keystore))\n$(word 3,$(keystore))\n\n\n' | keytool -genkey -v -keystore $@ -alias $(word 2,$(keystore)) -dname "CN=Android Debug,O=Android,C=US" -validity 365 -keyalg RSA -keysize 2048
endif

$(apk): $(shell find src/main/kotlin -name '*.kt') $(shell find src/main/java -name '*.java') $(shell find src/main/res) build.gradle $(word 1,$(keystore)).keystore src/main/AndroidManifest.xml $(temp) $(subst %,.,$(generated)) $(output)/assets/flutter_assets/AssetManifest.json $(pwd/flutter)/bin/cache/artifacts/engine/android-arm-release/flutter.jar
	@./gradlew -Pandroid.debug.obsoleteApi=true assemble$(if $(filter noaot,$(debug)),Debug,Release) --console verbose --warning-mode all \
	    -PorcUnique='$(domain).$(name)' -PorcName='$(name)' -PorcOutput='$(output)' \
	    -PorcStore='$(word 1,$(keystore)).keystore' -PorcAlias='$(word 2,$(keystore))' -PorcPassword='$(word 3,$(keystore))' \
	    -PorcMonotonic='$(monotonic)' -PorcRevision='$(revision)' -PorcCommit='$(commit)' -PorcVersion='$(version)' \
	    -PorcFlutter=$(pwd/flutter)/bin/cache/artifacts/engine/$(flutter/$(machine))$(engine)/flutter.jar -PorcInterface='$(pwd/gui)'
	exit 0
	touch $@

$(output)/$(name).apk: $(apk)
	cp -af $< $@

.PHONY: apk
apk: $(output)/$(name).apk
