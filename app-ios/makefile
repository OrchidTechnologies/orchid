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


version := 0.9

cflags += '-DORCHID_DOMAIN="$(domain)"'
cflags += '-DORCHID_NAME="$(name)"'

bundle := $(output)/Payload/$(name).app
signed := 
resources := 

.PHONY: all
all: $(output)/$(name).ipa

.PHONY: app
app: $(bundle)$(signature)

.PHONY: test
test: $(output)/orchid
	$(output)/orchid


include vpn/target.mk

cflags += -I.

frameworks := 
frameworks += Flutter
frameworks += SafariServices
frameworks += UIKit

local := 
local += $(output)/app.o

local += $(output)/ios/Runner/GeneratedPluginRegistrant.o
$(output)/ios/Runner/GeneratedPluginRegistrant.o: ios/Runner/GeneratedPluginRegistrant.m ios/Pods/Manifest.lock
app.o: ios/Runner/GeneratedPluginRegistrant.m

cflags += -Iios/Pods/Headers/Public

ios/Pods/Manifest.lock: ios/Podfile .flutter-plugins
	cd ios && pod install

out-$(target)/XCBuildData/build.db: ios/Pods/Manifest.lock
	xcodebuild -project ios/Pods/Pods.xcodeproj -alltargets -arch $(arch) -sdk $(sdk) SYMROOT=../../out-$(target)

$(output)/%.o: /%.m ios/Pods/Manifest.lock
	@mkdir -p $(dir $@)
	@echo [CC] $<
	$(cycc) -fobjc-arc -MD -c -o $@ $< $(cflags) $(c_)

resources += PureVPN.ovpn


include env/output.mk

include vpn/shared/p2p/depend.mk

-include $(output)/app.d
-include $(output)/main.d
-include $(output)/tunnel.d


cflags += -Fflutter/bin/cache/artifacts/engine/ios
lflags += -Fflutter/bin/cache/artifacts/engine/ios

include flutter.mk


$(output)/ents-%.xml: ents-%.xml.in
	@mkdir -p $(dir $@)
	sed -e 's/@MONOTONIC@/$(monotonic)/g; s/@VERSION@/$(version)/g; s/@DOMAIN@/$(domain)/g; s/@NAME@/$(name)/g; s/@TEAMID@/$(teamid)/g' $< >$@


ifneq ($(target),sim)
$(bundle)/PlugIns/$(name).VPN.appex/$(name).VPN: $(output)/tunnel.o $(object) $(linked)
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cycp) -o $@ $^ $(lflags) -e _NSExtensionMain -framework UIKit -framework JavaScriptCore

$(bundle)/PlugIns/$(name).VPN.appex/Info.plist: info-vpn.plist.in
	@mkdir -p $(dir $@)
	sed -e 's/@MONOTONIC@/$(monotonic)/g; s/@VERSION@/$(version)/g; s/@DOMAIN@/$(domain)/g; s/@NAME@/$(name)/g; s/@TEAMID@/$(teamid)/g' $< >$@

signed += $(bundle)/PlugIns/$(name).VPN.appex$(signature)
$(bundle)/PlugIns/$(name).VPN.appex$(signature): $(output)/ents-$(target)-vpn.xml $(bundle)/PlugIns/$(name).VPN.appex/Info.plist $(bundle)/PlugIns/$(name).VPN.appex/$(name).VPN
	@rm -rf $(dir $@)
	xattr -cr $(bundle)/PlugIns/$(name).VPN.appex
	$(xcode) codesign --deep -fs $(codesign) --entitlement $< -v $(bundle)/PlugIns/$(name).VPN.appex
	@touch $@
endif


signed += $(bundle)/AppIcon.png
$(bundle)/AppIcon.png: AppIcon.png
	cp -a $< $@

signed += $(bundle)/$(name)
$(bundle)/$(name): $(local) out-$(target)/XCBuildData/build.db
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cycp) -o $@ $(filter %.o,$^) $(lflags) -rpath "@executable_path/Frameworks" $(patsubst %,-framework %,$(frameworks)) out-$(target)/Release-$(sdk)/libPods-Runner.a out-$(target)/Release-$(sdk)/*/lib*.a

signed += $(bundle)/Info.plist
$(bundle)/Info.plist: info-main.plist.in
	@mkdir -p $(dir $@)
	sed -e 's/@MONOTONIC@/$(monotonic)/g; s/@VERSION@/$(version)/g; s/@DOMAIN@/$(domain)/g; s/@NAME@/$(name)/g; s/@TEAMID@/$(teamid)/g' $< >$@

signed += $(bundle)/Base.lproj/LaunchScreen.storyboardc
$(bundle)/Base.lproj/LaunchScreen.storyboardc: LaunchScreen.storyboard
	$(xcode) xcrun ibtool --errors --warnings --notices --module Runner --auto-activate-custom-fonts --target-device iphone --target-device ipad --minimum-deployment-target 8.0 --output-format human-readable-text --compilation-directory $(dir $@) $<


signed += $(patsubst %,$(bundle)/%,$(resources))
$(bundle)/%: resource/%
	@mkdir -p $(dir $@)
	cp -af $< $@
	@touch $@


$(bundle)$(signature): $(output)/ents-$(target)-main.xml $(signed)
	@rm -rf $(dir $@)
	xattr -cr $(bundle)
	$(xcode) codesign --deep -fs $(codesign) --entitlement $< -v $(bundle)
	@touch $@

$(output)/$(name).ipa: $(bundle)$(signature)
	@rm -f $@
	cd $(output); zip -r9Xy $(name).ipa Payload


$(output)/orchid: $(output)/main.o $(object) $(linked)
	@echo [LD] $@
	@set -o pipefail; $(cycp) -o $@ $^ $(lflags) 2>&1 | nl
