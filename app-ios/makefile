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


target := ios
include env/target.mk

cflags += -DGUI_$(gui)

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

cflags += -I.

frameworks := 
frameworks += Flutter
frameworks += SafariServices
frameworks += UIKit
frameworks += StoreKit

ifeq ($(target),sim)
cflags += -Wno-deprecated-declarations
lflags += -framework NetworkExtension
else
$(call include,vpn/target.mk)
endif

$(call include,shared/target-ios.mk)

local := 
local += app.mm.o

temp := $(subst %,.,$(word 1,$(generated)))
local += $(temp).o

$(call depend,$(temp).o,$(output)/XCBuildData/build.db)
cflags/$(temp) += -fmodules $(patsubst %,-fmodule-map-file=%,$(wildcard $(output)/Release-$(sdk)/*/*.modulemap)) -Wno-ignored-attributes

include env/output.mk

define _
-include $(patsubst %.o,$(output)/$(1)/%.d,$(local))
endef
$(each)


ifneq ($(target),sim)
$(bundle)/PlugIns/$(name).VPN.appex/$(name).VPN: $(patsubst %,$(output)/$(machine)/%,$(object) $(linked))
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cxx) $(more/$(machine)) $(wflags) -fobjc-link-runtime -fapplication-extension -e _NSExtensionMain -o $@ $^ $(lflags) -framework UIKit -framework JavaScriptCore
	@openssl sha256 -r $@

$(bundle)/PlugIns/$(name).VPN.appex/Info.plist: info-vpn.plist.in
	@mkdir -p $(dir $@)
	$(replace)

signed += $(bundle)/PlugIns/$(name).VPN.appex$(signature)
$(bundle)/PlugIns/$(name).VPN.appex$(signature): $(output)/ents-$(target)-vpn.plist $(bundle)/PlugIns/$(name).VPN.appex/Info.plist $(bundle)/PlugIns/$(name).VPN.appex/$(name).VPN
	@rm -rf $(dir $@)
	$(call codesign,$(bundle)/PlugIns/$(name).VPN.appex,$<,$@)

ifneq ($(provision),)
ifeq ($(identity),)
identity := $(shell $(unlock) comm -12 <(env/certificates.sh $(word 1,$(keychain)) | sort) <(env/identity.sh $(provision)app.mobileprovision | sort))
endif
ifeq ($(teamid),)
teamid := $(shell env/teamid.sh $(provision)app.mobileprovision)
endif

$(bundle)/PlugIns/$(name).VPN.appex$(signature): $(bundle)/PlugIns/$(name).VPN.appex/embedded.mobileprovision
$(bundle)/PlugIns/$(name).VPN.appex/embedded.mobileprovision: $(provision)vpn.mobileprovision
	cp -f $< $@

signed += $(bundle)/embedded.mobileprovision
$(bundle)/embedded.mobileprovision: $(provision)app.mobileprovision
	cp -f $< $@
endif
endif


signed += $(bundle)/$(name)
$(bundle)/$(name): $(patsubst %,$(output)/$(machine)/%,$(local)) $(output)/XCBuildData/build.db
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cxx) $(more/$(machine)) $(wflags) -o $@ $(filter %.o,$^) $(lflags) -rpath /usr/lib/swift -rpath "@executable_path/Frameworks" $(patsubst %,-framework %,$(frameworks)) $(output)/Release-$(sdk)/libPods-Runner.a $(output)/Release-$(sdk)/*/lib*.a $(foreach pod,$(wildcard $(pwd/gui)/ios/Pods/*/Frameworks/*.framework),-F$(dir $(pod))) -L$(isysroot)/usr/lib/swift -L$(toolchain)/usr/lib/swift{-5.0,}/$(sdk) -lobjc

signed += $(bundle)/Info.plist
$(bundle)/Info.plist: info-app.plist.in
	@mkdir -p $(dir $@)
	$(replace)


signed += $(bundle)/Base.lproj/LaunchScreen.storyboardc
$(bundle)/Base.lproj/LaunchScreen.storyboardc: LaunchScreen.storyboard
	@mkdir -p $(output)/info
	ibtool --output-format human-readable-text --errors --warnings --notices \
	    --target-device iphone --target-device ipad --minimum-deployment-target 8.0 \
	    --module Runner --auto-activate-custom-fonts \
	    --output-partial-info-plist $(output)/info/ibtool.plist \
	    --compilation-directory $(dir $@) $< 2>&1 | cat

signed += $(bundle)/Assets.car
$(bundle)/Assets.car: $(wildcard Assets.xcassets/*/*)
	@mkdir -p $(output)/info
	# XXX: --launch-image LaunchImage
	actool --output-format human-readable-text --errors --warnings --notices \
	    --target-device iphone --target-device ipad --minimum-deployment-target 13.0 \
	    --platform iphoneos \
	    --app-icon AppIcon \
	    --compress-pngs \
	    --enable-on-demand-resources YES \
	    --output-partial-info-plist $(output)/info/actool.plist \
	    --compile $(bundle) Assets.xcassets 2>&1 | cat

signed += $(patsubst resource/%,$(bundle)$(contents)$(resources)/%,$(wildcard resource/*))
$(bundle)$(contents)$(resources)/%: resource/%
	@mkdir -p $(dir $@)
	cp -af $< $@
	@touch $@


$(bundle)$(signature): $(output)/ents-$(target)-app.plist $(signed)
	@rm -rf $(dir $@)
	$(call codesign,$(bundle),$<,$@)

$(output)/$(name).ipa: $(bundle)$(signature)
	@rm -f $@
	cd $(output) && zip -rXy $(zflags) $(name).ipa Payload
