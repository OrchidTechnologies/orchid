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


include shared/target-all.mk
engine := $(pwd/flutter)/bin/cache/artifacts/engine/$(platform)$(engine)

ifeq ($(filter ldid,$(debug)),)
unlock := $(if $(keychain),security unlock-keychain -p $(word 2,$(keychain)) $(word 1,$(keychain)) &&)
codesign = xattr -cr $(1) && $(unlock) codesign -vfs $(identity) --entitlements $(2) --generate-entitlement-der $(1)
else
ifneq ($(identity),)
# XXX: the ldid in homebrew doesn't actually work :(
codesign = ldid -K$(identity) -S$(2) $(1)
else
codesign = mkdir -p $(dir $(3))
endif
endif

codesign += && touch $(3)

ifeq ($(target),mac)
cflags += -F$(engine)
lflags += -F$(engine)
else
cflags += -F$(engine)/$(framework).xcframework/$(xcframework)
lflags += -F$(engine)/$(framework).xcframework/$(xcframework)
endif

app := $(bundle)$(contents)/Frameworks/App.framework
embed := $(bundle)$(contents)/Frameworks/$(framework).framework

ifeq ($(target),mac)
temp := 
else
temp := $(pwd/gui)/ios/Flutter/AppFrameworkInfo.plist
$(temp): $(pwd/flutter)/packages/flutter_tools/templates/app_shared/ios.tmpl/Flutter/AppFrameworkInfo.plist
	mkdir -p $(dir $@)
	cp -f $< $@
endif

rsync := rsync -a --chmod=+rX --delete $(patsubst %,--filter "- %",.DS_Store _CodeSignature Headers Modules)

$(app)$(versions)$(resources)/Info%plist $(embed)$(versions)$(resources)/Info%plist: $(dart) $(temp)
	rm -rf .dart_tool/flutter_build $(output)/flutter
	cd $(pwd/gui) && MACOSX_DEPLOYMENT_TARGET=10.15 $(flutter) assemble \
	    -dAction="build" \
	    -dTargetPlatform="$(platform)" \
	    -dTargetFile="lib/main.dart" \
	    -dSdkRoot="$(isysroot)" \
	    -dBuildMode="$(mode)" \
	    -d$(capped)Archs="$(machine)" \
	    -dTreeShakeIcons="false" \
	    -dTrackWidgetCreation="true" \
	    -dDartObfuscation="false" \
	    -dSplitDebugInfo="" \
	    --DartDefines="" \
	    --ExtraGenSnapshotOptions="" \
	    --ExtraFrontEndOptions="" \
	    --output="$(CURDIR)/$(output)/flutter" \
	    $(mode)_$(assemble)_bundle_flutter_assets
	@mkdir -p $(dir $(app)) $(dir $(embed))
ifeq ($(target),mac)
	$(rsync) $(output)/flutter/$(framework).framework $(dir $(embed))
else
	$(rsync) --filter '- $(framework)' $(engine)/$(framework).xcframework/$(xcframework)/Flutter.framework $(dir $(embed))
	xcrun bitcode_strip -r $(engine)/$(framework).xcframework/$(xcframework)/Flutter.framework/Flutter -o $(embed)/$(framework)
endif
	$(rsync) $(output)/flutter/App.framework $(dir $(app))
	find $(app) ! -perm 755 -a ! -perm 644 -exec chmod -v 644 {} +
	touch $(patsubst %,%$(versions)$(resources)/Info.plist,$(app) $(embed))

signed += $(app)$(versions)$(signature)
$(app)$(versions)$(signature): shared/empty.plist $(app)$(versions)$(resources)/Info.plist
	@rm -rf $(dir $@)
	$(call codesign,$(app),$<,$@)

signed += $(embed)$(versions)$(signature)
$(embed)$(versions)$(signature): shared/empty.plist $(embed)$(versions)$(resources)/Info.plist
	@rm -rf $(dir $@)
	$(call codesign,$(embed),$<,$@)


cflags += -I$(pwd/gui)/$(assemble)/Pods/Headers/Public

$(pwd/gui)/$(assemble)/Pods/Manifest.lock: $(pwd/gui)/$(assemble)/Podfile $(pwd/gui)/.flutter-plugins
	cd $(pwd/gui)/$(assemble) && pod install
	touch $@

$(output)/XCBuildData/build.db: shared/empty.plist $(pwd/gui)/$(assemble)/Pods/Manifest.lock
	@mkdir -p "$(bundle)$(contents)"
	cd $(pwd/gui) && xcodebuild -project $(assemble)/Pods/Pods.xcodeproj -alltargets -arch $(machine) -sdk $(sdk) SYMROOT=$(CURDIR)/$(output)
	shopt -s nullglob; for framework in $(output)/Release/*/*.framework; do \
	    $(rsync) "$${framework}" "$(bundle)$(contents)/Frameworks"; \
	    framework="$(bundle)$(contents)/Frameworks/$${framework##*/}"; \
	    $(call codesign,$${framework},$<,$${framework}$(versions)$(signature)); \
	done


replace = sed -e 's/@MONOTONIC@/$(monotonic)/g; s/@VERSION@/$(version)/g; s/@REVISION@/$(revision)/g; s/@DOMAIN@/$(domain)/g; s/@NAME@/$(name)/g; s/@TEAMID@/$(teamid)/g; s/@SUPPORT@/$(support)/g' $< | if test -n "$(filter noaot,$(debug))"; then sed -e 's/^@D@/   /'; else sed -e '/^@D@/d'; fi | if $(beta); then sed -e 's/^@B@/   /'; else sed -e '/^@B@/d'; fi >$@

$(output)/ents-%.plist: ents-%.plist.in
	@mkdir -p $(dir $@)
	$(replace)
