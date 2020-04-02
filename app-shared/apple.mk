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


include shared/flutter.mk

cflags += -Fflutter/bin/cache/artifacts/engine/$(platform)
lflags += -Fflutter/bin/cache/artifacts/engine/$(platform)

app := $(bundle)$(contents)/Frameworks/App.framework
embed := $(bundle)$(contents)/Frameworks/$(framework).framework

ifeq ($(target),mac)
generated := 
temp := 
else
generated := ios/Runner/GeneratedPluginRegistrant%m
temp := ios/Flutter/AppFrameworkInfo.plist
$(temp): flutter/packages/flutter_tools/templates/app/ios.tmpl/Flutter/AppFrameworkInfo.plist
	mkdir -p $(dir $@)
	cp -f $< $@
endif

rsync := rsync -a --delete $(patsubst %,--filter "- %",.DS_Store _CodeSignature Headers Modules)

$(app)$(versions)$(resources)/Info%plist $(embed)$(versions)$(resources)/Info%plist $(generated): $(dart) $(temp)
	rm -rf $(app) $(embed)
	$(flutter) assemble \
	    -dTargetPlatform="$(platform)" \
	    -dTargetFile="lib/main.dart" \
	    -dBuildMode="$(mode)" \
	    -dIosArchs="$(default)" \
	    -dTreeShakeIcons="false" \
	    -dTrackWidgetCreation="" \
	    -dDartObfuscation="false" \
	    -dSplitDebugInfo="" \
	    -dEnableBitcode="" \
	    -dDartDefines="" \
	    -dExtraFrontEndOptions="" \
	    --output="$(bundle)$(contents)/Frameworks" \
	   "$(mode)_$(assemble)_bundle_flutter_assets"
ifeq ($(target),mac)
	rm -rf $(dir $(embed))$(framework).framework{,$(versions)}/{Headers,Modules}
else
	$(rsync) $(engine)/Flutter.framework $(dir $(embed))
endif
	touch $(patsubst %,%$(versions)$(resources)/Info.plist,$(app) $(embed))

signed += $(app)$(versions)$(signature)
$(app)$(versions)$(signature): $(output)/ents-$(target)-dart.xml $(app)$(versions)$(resources)/Info.plist
	@rm -rf $(dir $@)
	xattr -cr $(app)
	codesign --deep -fs $(codesign) --entitlement $< -v $(app)
	@touch $@

signed += $(embed)$(versions)$(signature)
$(embed)$(versions)$(signature): $(output)/ents-$(target)-flutter.xml $(embed)$(versions)$(resources)/Info.plist
	@rm -rf $(dir $@)
	xattr -cr $(embed)
	codesign --deep -fs $(codesign) --entitlement $< -v $(embed)
	@touch $@
