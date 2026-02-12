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
all: apk

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

apk := $(output)/build/outputs/apk/$(mode)/app-android-$(if $(filter noaot,$(debug)),debug,release-unsigned).apk

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

$(pwd/flutter)/bin/cache/artifacts/engine/android-%$(engine)/flutter.jar: $(pwd/flutter)/packages/flutter_tools/pubspec.lock
	@

temp := $(foreach arch,$(jni),$(foreach base,orchid flutter $(if $(filter noaot,$(debug)),,app),$(output)/jnilibs/$(arch)/lib$(base).so))

$(output)/jnilibs/%/libflutter.so: $(pwd/flutter)/bin/cache/artifacts/engine/$$(flutter/$$*)$(engine)/flutter.jar
	@mkdir -p $(dir $@)
	unzip -p $< lib/$*/libflutter.so >$@

$(apk): $(shell find src/main/kotlin -name '*.kt') $(shell find src/main/java -name '*.java') $(shell find src/main/res) build.gradle src/main/AndroidManifest.xml $(temp) $(subst %,.,$(generated)) $(output)/assets/flutter_assets/AssetManifest.json $(pwd/flutter)/bin/cache/artifacts/engine/android-arm-release/flutter.jar
	@FLUTTER_ROOT=$(CURDIR)/shared/flutter ./gradlew assemble$(if $(filter noaot,$(debug)),Debug,Release) \
	    -Pandroid.debug.obsoleteApi=true --console verbose --warning-mode all \
	    -PorcMonotonic='$(monotonic)' -PorcRevision='$(revision)' -PorcPackage='$(package)' -PorcVersion='$(version)' \
	     -PorcFlutter=$(pwd/flutter)/bin/cache/artifacts/engine/$(flutter/$(machine))$(engine)/flutter.jar \
	    -PorcUnique='$(domain).$(name)' -PorcName='$(name)' -PorcOutput='$(output)' -PorcInterface='$(pwd/gui)'
	exit 0
	touch $@

$(output)/$(name).apk: $(apk)
	$(ANDROID_SDK_ROOT)/build-tools/35.0.0/apksigner sign \
	    --alignment-preserved \
	    --deterministic-dsa-signing --min-sdk-version $(aver) \
	    $(apksigner) --out $@ $<

.PHONY: apk
ifeq ($(apksigner),)
apk: $(apk)
else
apk: $(output)/$(name).apk
endif
