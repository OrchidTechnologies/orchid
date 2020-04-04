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


target := mac
include env/target.mk

cflags += '-DORCHID_DOMAIN="$(domain)"'
cflags += '-DORCHID_NAME="$(name)"'

bundle := $(output)/Payload/$(name).app

assemble := macos
platform := darwin-x64
framework := FlutterMacOS

signed := 

.PHONY: all
all: $(bundle)$(contents)$(signature)

.PHONY: test
test: $(bundle)$(contents)$(signature)
	$(bundle)$(contents)/MacOS/$(name)

$(call include,vpn/target.mk)

cflags += -I.

frameworks := 
frameworks += $(framework)
frameworks += AppKit
frameworks += SafariServices

pods := $(wildcard out-mac/Release/*/*.framework)
swifts := $(wildcard *.swift) macos/Flutter/GeneratedPluginRegistrant.swift

local := 
local += app.mm.o

local += $(patsubst %,%.o,$(swifts))
$(foreach swift,$(swifts),$(call depend,$(swift).o,macos/Pods/Manifest.lock))

cflags += -Imacos/Pods/Headers/Public

macos/Pods/Manifest.lock: macos/Podfile .flutter-plugins
	cd macos && pod install
	touch $@

$(output)/XCBuildData/build.db: macos/Pods/Manifest.lock
	xcodebuild -project macos/Pods/Pods.xcodeproj -alltargets -arch $(default) -sdk $(sdk) SYMROOT=../../$(output)


include env/output.mk

$(output)/%.swift.o: $$(specific) $$(folder).swift $$(code) $(swifts)
	$(specific)
	@mkdir -p $(dir $@)
	@echo [CC] $(target)/$(arch) $<
	swift -frontend -sdk $(path) -c -o $@ -primary-file $< $(filter-out $<,$(swifts)) -module-name $(name) -Fmacos/Flutter/ephemeral/.symlinks/flutter/darwin-x64 $(foreach pod,$(pods),-F$(dir $(pod)))
	@touch $@

define _
-include $(patsubst %.o,$(output)/$(1)/%.d,$(local))
endef
$(each)


replace = sed -e 's/@MONOTONIC@/$(monotonic)/g; s/@VERSION@/$(version)/g; s/@REVISION@/$(revision)/g; s/@DOMAIN@/$(domain)/g; s/@NAME@/$(name)/g; s/@TEAMID@/$(teamid)/g; s/@SUPPORT@/$(support)/g' $< | if test -n "$(filter noaot,$(debug))"; then sed -e 's/^@D@/   /'; else sed -e '/^@D@/d'; fi | if $(beta); then sed -e 's/^@B@/   /'; else sed -e '/^@B@/d'; fi >$@


include shared/apple.mk


$(output)/ents-%.xml: ents-%.xml.in
	@mkdir -p $(dir $@)
	$(replace)


$(bundle)$(contents)/PlugIns/$(name).VPN.appex$(contents)/MacOS/$(name).VPN: $(patsubst %,$(output)/$(default)/%,$(object) $(linked))
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cxx/$(default)) $(wflags) -o $@ $^ $(lflags) -e _NSExtensionMain -framework JavaScriptCore
	@openssl sha256 -r $@

$(bundle)$(contents)/PlugIns/$(name).VPN.appex$(contents)/Info.plist: info-vpn.plist.in
	@mkdir -p $(dir $@)
	$(replace)

signed += $(bundle)$(contents)/PlugIns/$(name).VPN.appex$(contents)$(signature)
$(bundle)$(contents)/PlugIns/$(name).VPN.appex$(contents)$(signature): $(output)/ents-$(target)-vpn.xml $(bundle)$(contents)/PlugIns/$(name).VPN.appex$(contents)/Info.plist $(bundle)$(contents)/PlugIns/$(name).VPN.appex$(contents)/MacOS/$(name).VPN
	@rm -rf $(dir $@)
	xattr -cr $(bundle)$(contents)/PlugIns/$(name).VPN.appex
	codesign --deep -fs $(codesign) --entitlement $< -v $(bundle)$(contents)/PlugIns/$(name).VPN.appex
	@touch $@

ifneq ($(provision),)
$(bundle)$(contents)/PlugIns/$(name).VPN.appex$(contents)$(signature): $(bundle)$(contents)/PlugIns/$(name).VPN.appex$(contents)/embedded.provisionprofile
$(bundle)$(contents)/PlugIns/$(name).VPN.appex$(contents)/embedded.provisionprofile: $(provision)vpn.provisionprofile
	cp -f $< $@

signed += $(bundle)$(contents)/embedded.provisionprofile
$(bundle)$(contents)/embedded.provisionprofile: $(provision)main.provisionprofile
	cp -f $< $@
endif

define _
$(eval temp := $(bundle)$(contents)/Frameworks/$(notdir $(1)))
signed += $(temp)$(versions)$(resources)/Info.plist
$(temp)$(versions)$(resources)/Info.plist: $(output)/XCBuildData/build.db
	$(rsync) $(1) $(dir $(temp))
	xattr -cr $(temp)
	codesign --deep -fs $(codesign) -v $(temp)
	@touch $$@
endef
$(foreach pod,$(pods),$(eval $(call _,$(pod))))

signed += $(bundle)$(contents)/MacOS/$(name)
$(bundle)$(contents)/MacOS/$(name): $(patsubst %,$(output)/$(default)/%,$(local)) $(output)/XCBuildData/build.db $(bundle)$(contents)/Frameworks/App.framework$(versions)$(resources)/Info.plist
	@mkdir -p $(dir $@)
	@echo [LD] $@
	$(cxx/$(default)) $(wflags) -o $@ $(filter %.o,$^) $(lflags) -rpath /usr/lib/swift -rpath @executable_path/../Frameworks $(patsubst %,-framework %,$(frameworks)) $(bundle)$(contents)/Frameworks/App.framework$(versions)/App $(output)/Release/Pods_Runner.framework$(versions)/Pods_Runner $(foreach pod,$(pods),-F$(dir $(pod))) -L/usr/lib/swift -L$(toolchain)/usr/lib/swift/$(sdk)

signed += $(bundle)$(contents)/PkgInfo
$(bundle)$(contents)/PkgInfo:
	echo -n 'APPL????' >$@

signed += $(bundle)$(contents)/Info.plist
$(bundle)$(contents)/Info.plist: info-main.plist.in
	@mkdir -p $(dir $@)
	$(replace)

signed += $(bundle)$(contents)$(resources)/Base.lproj/MainMenu.nib
$(bundle)$(contents)$(resources)/Base.lproj/MainMenu.nib: MainMenu.xib
	@mkdir -p $(output)/info
	ibtool --output-format human-readable-text --errors --warnings --notices \
	    --target-device mac --minimum-deployment-target 10.11 \
	    --module Runner --auto-activate-custom-fonts \
	    --output-partial-info-plist $(output)/info/ibtool.plist \
	    --compile $@ $< 2>&1 | cat

signed += $(bundle)$(contents)$(resources)/Assets.car
$(bundle)$(contents)$(resources)/Assets.car: $(wildcard Assets.xcassets/*/*)
	@mkdir -p $(dir $@)
	@mkdir -p $(output)/info
	# XXX: --launch-image LaunchImage
	# XXX: --export-dependency-info depends.txt
	actool --output-format human-readable-text --errors --warnings --notices \
	    --target-device mac --minimum-deployment-target 10.11 \
	    --platform macosx --product-type com.apple.product-type.application \
	    --app-icon AppIcon \
	    --enable-on-demand-resources NO \
	    --sticker-pack-identifier-prefix "$(domain).$(name).sticker-pack." \
	    --output-partial-info-plist $(output)/info/actool.plist \
	    --compile $(bundle)$(contents)$(resources) Assets.xcassets 2>&1 | cat

signed += $(patsubst resource/%,$(bundle)$(contents)$(resources)/%,$(wildcard resource/*))
$(bundle)$(contents)$(resources)/%: resource/%
	@mkdir -p $(dir $@)
	cp -af $< $@
	@touch $@


$(bundle)$(contents)$(signature): $(output)/ents-$(target)-main.xml $(signed)
	@rm -rf $(dir $@)
	xattr -cr $(bundle)
	codesign -fs $(codesign) --entitlement $< -v $(bundle)
	@touch $@

$(output)/$(name).dmg: $(bundle)$(contents)$(signature)
	@rm -f $@
	cd $(output); zip -rXy0 $(name).dmg Payload
