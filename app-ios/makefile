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


target := ios
include env/target.mk

cflags += '-DORCHID_DOMAIN="$(domain)"'
cflags += '-DORCHID_NAME="$(name)"'

bundle := $(output)/Payload/$(name).app
signed := 

.PHONY: all
all: $(output)/$(name).ipa

.PHONY: app
app: $(bundle)$(signature)

.PHONY: install
install: $(output)/$(name).ipa
	ideviceinstaller -i $<

.PHONY: validate
validate: $(output)/$(name).ipa
	xcrun altool --validate-app -f $< -t ios -u "$(aluser)" -p $(alpass)

.PHONY: upload
upload: $(output)/$(name).ipa
	xcrun altool --upload-app -f $< -t ios -u "$(aluser)" -p $(alpass)

ifeq ($(target),sim)
cflags += -Wno-deprecated-declarations
lflags += -framework NetworkExtension
else
$(call include,vpn/target.mk)
endif

cflags += -I.

frameworks := 
frameworks += Flutter
frameworks += SafariServices
frameworks += UIKit

local := 
local += app.mm.o

local += ios/Runner/GeneratedPluginRegistrant.m.o
$(call depend,ios/Runner/GeneratedPluginRegistrant.m.o,ios/Pods/Manifest.lock)

cflags += -Iios/Pods/Headers/Public

ios/Pods/Manifest.lock: ios/Podfile .flutter-plugins
	cd ios && pod install
	touch $@

$(output)/XCBuildData/build.db: ios/Pods/Manifest.lock
	xcodebuild -project ios/Pods/Pods.xcodeproj -alltargets -arch $(default) -sdk $(sdk) SYMROOT=../../$(output)


include env/output.mk

define _
-include $(patsubst %.o,$(output)/$(1)/%.d,$(local))
endef
$(each)


replace = sed -e 's/@MONOTONIC@/$(monotonic)/g; s/@VERSION@/$(version)/g; s/@REVISION@/$(revision)/g; s/@DOMAIN@/$(domain)/g; s/@NAME@/$(name)/g; s/@TEAMID@/$(teamid)/g; s/@SUPPORT@/$(support)/g' $< | if test -n "$(filter noaot,$(debug))"; then sed -e 's/^@D@/   /'; else sed -e '/^@D@/d'; fi | if $(beta); then sed -e 's/^@B@/   /'; else sed -e '/^@B@/d'; fi >$@


cflags += -Fflutter/bin/cache/artifacts/engine/ios
lflags += -Fflutter/bin/cache/artifacts/engine/ios

include flutter.mk


$(output)/ents-%.xml: ents-%.xml.in
	@mkdir -p $(dir $@)
	$(replace)


ifneq ($(target),sim)
$(bundle)/PlugIns/$(name).VPN.appex/$(name).VPN: $(patsubst %,$(output)/$(default)/%,$(object) $(linked))
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cxx/$(default)) $(wflags) -o $@ $^ $(lflags) -e _NSExtensionMain -framework UIKit -framework JavaScriptCore

$(bundle)/PlugIns/$(name).VPN.appex/Info.plist: info-vpn.plist.in
	@mkdir -p $(dir $@)
	$(replace)

signed += $(bundle)/PlugIns/$(name).VPN.appex$(signature)
$(bundle)/PlugIns/$(name).VPN.appex$(signature): $(output)/ents-$(target)-vpn.xml $(bundle)/PlugIns/$(name).VPN.appex/Info.plist $(bundle)/PlugIns/$(name).VPN.appex/$(name).VPN
	@rm -rf $(dir $@)
	xattr -cr $(bundle)/PlugIns/$(name).VPN.appex
	codesign --deep -fs $(codesign) --entitlement $< -v $(bundle)/PlugIns/$(name).VPN.appex
	@touch $@

$(bundle)/PlugIns/$(name).VPN.appex$(signature): $(bundle)/PlugIns/$(name).VPN.appex/GeoLite2-City.mmdb

ifneq ($(provision),)
$(bundle)/PlugIns/$(name).VPN.appex$(signature): $(bundle)/PlugIns/$(name).VPN.appex/embedded.mobileprovision
$(bundle)/PlugIns/$(name).VPN.appex/embedded.mobileprovision: $(provision)vpn.mobileprovision
	cp -f $< $@

signed += $(bundle)/embedded.mobileprovision
$(bundle)/embedded.mobileprovision: $(provision)main.mobileprovision
	cp -f $< $@
endif
endif


signed += $(bundle)/$(name)
$(bundle)/$(name): $(patsubst %,$(output)/$(default)/%,$(local)) $(output)/XCBuildData/build.db
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cxx/$(default)) $(wflags) -o $@ $(filter %.o,$^) $(lflags) -rpath "@executable_path/Frameworks" $(patsubst %,-framework %,$(frameworks)) $(output)/Release-$(sdk)/libPods-Runner.a $(output)/Release-$(sdk)/*/lib*.a

signed += $(bundle)/Info.plist
$(bundle)/Info.plist: info-main.plist.in
	@mkdir -p $(dir $@)
	$(replace)

signed += $(bundle)/Base.lproj/LaunchScreen.storyboardc
$(bundle)/Base.lproj/LaunchScreen.storyboardc: LaunchScreen.storyboard
	ibtool --errors --warnings --notices --module Runner --auto-activate-custom-fonts --target-device iphone --target-device ipad --minimum-deployment-target 8.0 --output-format human-readable-text --compilation-directory $(dir $@) $< 2>&1 | cat


signed += $(bundle)/Assets.car
$(bundle)/Assets.car: $(wildcard Images.xcassets/*/*)
	@mkdir -p $(output)/info
	# XXX: --launch-image LaunchImage
	actool --output-format human-readable-text --notices --warnings \
	    --app-icon AppIcon \
	    --compress-pngs --enable-on-demand-resources YES \
	    --platform iphoneos --minimum-deployment-target 11.0 \
	    --target-device iphone --target-device ipad \
	    --output-partial-info-plist $(output)/info/actool.plist \
	    --compile $(bundle) Images.xcassets 2>&1 | cat

signed += $(patsubst resource/%,$(bundle)/%,$(wildcard resource/*))
$(bundle)/%: resource/%
	@mkdir -p $(dir $@)
	cp -af $< $@
	@touch $@


$(bundle)$(signature): $(output)/ents-$(target)-main.xml $(signed)
	@rm -rf $(dir $@)
	xattr -cr $(bundle)
	codesign --deep -fs $(codesign) --entitlement $< -v $(bundle)
	@touch $@

ifeq ($(filter nocompress,$(debug)),)
zflags := -9
else
zflags := -0
endif

$(output)/$(name).ipa: $(bundle)$(signature)
	@rm -f $@
	cd $(output); zip -rXy $(zflags) $(name).ipa Payload
