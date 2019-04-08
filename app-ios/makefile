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

.PHONY: test
test: $(output)/orchid
	$(output)/orchid


include vpn/target.mk

cflags += -I.


resources += PureVPN.ovpn


include env/output.mk

include vpn/shared/p2p/depend.mk

-include $(output)/app.d
-include $(output)/main.d
-include $(output)/tunnel.d


cflags += -Fflutter/bin/cache/artifacts/engine/ios
lflags += -Fflutter/bin/cache/artifacts/engine/ios

signed += build/app.dill
include flutter.mk


$(output)/ents-%.xml: ents-%.xml.in
	@mkdir -p $(dir $@)
	sed -e 's/@MONOTONIC@/$(monotonic)/g; s/@VERSION@/$(version)/g; s/@DOMAIN@/$(domain)/g; s/@NAME@/$(name)/g; s/@TEAMID@/$(teamid)/g' $< >$@


$(bundle)/PlugIns/$(name).VPN.appex/$(name).VPN: $(output)/tunnel.o $(object)
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cycc) -o $@ $^ $(lflags) -e _NSExtensionMain -framework UIKit -framework JavaScriptCore

$(bundle)/PlugIns/$(name).VPN.appex/Info.plist: info-vpn.plist.in
	@mkdir -p $(dir $@)
	sed -e 's/@MONOTONIC@/$(monotonic)/g; s/@VERSION@/$(version)/g; s/@DOMAIN@/$(domain)/g; s/@NAME@/$(name)/g; s/@TEAMID@/$(teamid)/g' $< >$@

signed += $(bundle)/PlugIns/$(name).VPN.appex$(signature)
$(bundle)/PlugIns/$(name).VPN.appex$(signature): $(output)/ents-vpn.xml $(bundle)/PlugIns/$(name).VPN.appex/Info.plist $(bundle)/PlugIns/$(name).VPN.appex/$(name).VPN
	@rm -rf $(dir $@)
	$(xcode) codesign --deep -fs $(codesign) --entitlement $< -v $(bundle)/PlugIns/$(name).VPN.appex
	@touch $@


signed += $(bundle)/$(name)
$(bundle)/$(name): $(output)/app.o
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cycc) -o $@ $^ $(lflags) -rpath "@executable_path/Frameworks" -framework Flutter -framework UIKit

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


$(bundle)$(signature): $(output)/ents-main.xml $(signed)
	@rm -rf $(dir $@)
	$(xcode) codesign --deep -fs $(codesign) --entitlement $< -v $(bundle)
	@touch $@

$(output)/$(name).ipa: $(bundle)$(signature)
	@rm -f $@
	cd $(output); zip -r9Xy $(name).ipa Payload


$(output)/orchid: $(output)/main.o $(object)
	@echo [LD] $@
	@set -o pipefail; $(cycc) -o $@ $^ $(lflags) 2>&1 | nl
