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


include $(pwd)/target-all.mk

rsync := rsync -a --delete

$(output)/package/data/flutter_assets/AssetManifest%json: $(dart)
	rm -rf .dart_tool/flutter_build $(output)/flutter
	$(flutter) assemble \
	    -dTargetPlatform="$(platform)" \
	    -dTargetFile="lib/main.dart" \
	    -dBuildMode="$(mode)" \
	    -dTreeShakeIcons="false" \
	    -dTrackWidgetCreation="true" \
	    --output="$(output)/flutter" \
	    $(mode)_bundle_$(assemble)_assets
	@mkdir -p $(dir $@)
	$(rsync) $(output)/flutter/flutter_assets/ $(dir $@)
signed += $(output)/package/data/flutter_assets/AssetManifest.json

source += $(filter-out \
    %/engine_method_result.cc \
    %_unittests.cc \
,$(wildcard $(pwd)/engine/shell/platform/common/cpp/client_wrapper/*.cc))

cflags += -I$(pwd)/gui/$(assemble)
source += $(subst %,.,$(generated))
header += $(subst %,.,$(generated))

# XXX: does flutter enforce that windows uses .cpp and linux uses .cc or is that an accident?
source += $(wildcard $(pwd)/gui/$(assemble)/flutter/ephemeral/.plugin_symlinks/*/$(assemble)/*.cc)
source += $(wildcard $(pwd)/gui/$(assemble)/flutter/ephemeral/.plugin_symlinks/*/$(assemble)/*.cpp)

cflags += $(patsubst %,-I%,$(wildcard $(pwd)/gui/$(assemble)/flutter/ephemeral/.plugin_symlinks/*/$(assemble)/include))
cflags += -DFLUTTER_PLUGIN_IMPL

template := $(pwd)/flutter/packages/flutter_tools/templates/app/$(assemble).tmpl

$(output)/package/data/icudtl.dat: flutter/bin/cache/artifacts/engine/$(platform)/icudtl.dat
	@mkdir -p $(dir $@)
	cp -f $< $@
signed += $(output)/package/data/icudtl.dat
