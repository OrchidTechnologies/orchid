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


assemble := android
platform := android

generated := $(pwd)/gui/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant%java

include $(pwd)/target-all.mk

jni := armeabi-v7a arm64-v8a
#jnis := $(subst $(space),$(comma),$(foreach arch,$(jni),android-$(flutter/$(arch))))

$(output)/flutter/flutter_assets/AssetManifest%json $(foreach arch,$(jni),$(output)/flutter/$(arch)/app%so): $(dart)
	rm -rf .dart_tool/flutter_build $(output)/flutter
	$(flutter) assemble \
	    -dTargetPlatform="$(platform)" \
	    -dTargetFile="lib/main.dart" \
	    -dBuildMode="$(mode)" \
	    -dTreeShakeIcons="true" \
	    -dTrackWidgetCreation="true" \
	    --output="$(output)/flutter" \
	    $(foreach arch,$(jni),android_aot_bundle_$(mode)_android-$(flutter/$(arch)))
