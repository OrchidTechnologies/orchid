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


assets := $(bundle)/Frameworks/App.framework/flutter_assets

include shared/flutter.mk

engine := flutter/bin/cache/artifacts/engine/ios$(engine)

ifeq ($(precompiled),)
$(bundle)/Frameworks/App.framework/App:
	@mkdir -p $(dir $@)
	echo "static const int Moo = 88;" | $(patsubst -miphoneos-version-min=11.0,-miphoneos-version-min=8.0,$(cc/$(default))) -dynamiclib -o $@ \
	    -x c - -Wno-unused-const-variable \
	    -Xlinker -rpath -Xlinker '@executable_path/Frameworks' \
	    -Xlinker -rpath -Xlinker '@loader_path/Frameworks' \
	    -install_name '@rpath/App.framework/App'
else
$(output)/aot/App.framework/App: $(dart)
	flutter/bin/flutter --suppress-analytics --verbose build aot -t lib/main.dart \
	    --target-platform=ios --$(mode) --output-dir=$(output)/aot

$(bundle)/Frameworks/App.framework/App: $(output)/aot/App.framework/App
	@mkdir -p $(dir $@)
	cp -f $< $@
endif

$(bundle)/Frameworks/App.framework/Info.plist: flutter/packages/flutter_tools/templates/app/ios.tmpl/Flutter/AppFrameworkInfo.plist
	@mkdir -p $(dir $@)
	cp -f $< $@

signed += $(bundle)/Frameworks/App.framework$(signature)
$(bundle)/Frameworks/App.framework$(signature): $(output)/ents-$(target)-dart.xml $(bundle)/Frameworks/App.framework/Info.plist $(bundle)/Frameworks/App.framework/App .flutter-plugins
	@rm -rf $(dir $@)
	codesign --deep -fs $(codesign) --entitlement $< -v $(bundle)/Frameworks/App.framework
	@touch $@

$(bundle)/Frameworks/Flutter.framework/Flutter: $(engine)/Flutter.framework/Flutter
	@mkdir -p $(dir $@)
	lipo $(patsubst %,-extract %,$(archs)) $< -output $@
	@touch $@

$(bundle)/Frameworks/Flutter.framework/%: $(engine)/Flutter.framework/%
	@mkdir -p $(dir $@)
	cp -af $< $@
	touch $@

signed += $(assets)/AssetManifest.json
$(assets)/AssetManifest%json %flutter-plugins ios/Runner/GeneratedPluginRegistrant%m: $(dart)
	rm -rf $(assets) $(output)/snapshot_blob.bin.d $(output)/snapshot_blob.bin.d.fingerprint
	@mkdir -p build $(output) $(assets)
	flutter/bin/flutter --suppress-analytics --verbose build bundle -t lib/main.dart \
	    --depfile="$(output)/snapshot_blob.bin.d" --asset-dir="$(assets)" --output-dill="$(output)/build.dill" \
	    --target-platform=ios --$(mode) $(precompiled)

# XXX: -include $(output)/snapshot_blob.bin.d

flutter := Flutter Info.plist icudtl.dat

$(patsubst %,$(engine)/Flutter.framework/%,$(flutter)): .flutter-plugins

signed += $(bundle)/Frameworks/Flutter.framework$(signature)
$(bundle)/Frameworks/Flutter.framework$(signature): $(output)/ents-$(target)-flutter.xml $(patsubst %,$(bundle)/Frameworks/Flutter.framework/%,$(flutter))
	@rm -rf $(dir $@)
	codesign --deep -fs $(codesign) --entitlement $< -v $(bundle)/Frameworks/Flutter.framework
	@touch $@
