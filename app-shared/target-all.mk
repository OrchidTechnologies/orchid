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


forks := 
include $(pwd/gui)/target.mk

pwd/flutter := $(pwd)/flutter
flutter := $(CURDIR)/$(pwd/flutter)/bin/flutter --suppress-analytics --verbose

# -a is needed as flutter (incorrectly) only installs files for windows *target* on windows *host*
# https://github.com/flutter/flutter/issues/58379
precache := --linux --macos --windows -a

$(pwd/flutter)/packages/flutter/pubspec.lock: $(pwd/flutter)/packages/flutter/pubspec.yaml $(call head,$(pwd/flutter))
	cd $(pwd/flutter) && git clean -fxd
	cd $(pwd/flutter) && bin/flutter config --enable-linux-desktop
	cd $(pwd/flutter) && bin/flutter config --enable-macos-desktop
	cd $(pwd/flutter) && bin/flutter config --enable-windows-desktop
	cd $(pwd/flutter) && bin/flutter precache $(precache)
	cd $(pwd/flutter) && bin/flutter update-packages

dart := 
dart += $(pwd/gui)/.dart_tool/package_config.json
dart += $(pwd/gui)/.flutter-plugins
dart += $(pwd/gui)/.packages

# XXX: use $(dart) to generate the first three of these
$(pwd/gui)/.dart_tool/package_config%json $(pwd/gui)/%flutter-plugins $(pwd/gui)/%packages $(generated): $(pwd/gui)/pubspec.yaml $(pwd/gui)/pubspec.lock $(pwd/flutter)/packages/flutter/pubspec.lock $(forks)
	@mkdir -p $(pwd/gui)/{android,ios,linux,macos,windows}
	@rm -f $(pwd/gui)/.flutter-plugins
	cd $(pwd/gui) && $(flutter) pub get
	@touch $(pwd/gui)/.packages

dart += $(shell find $(pwd/gui)/lib/ -name '*.dart')

ifeq ($(filter noaot,$(debug)),)
mode := release
engine := -release
precompiled := --precompiled
else
mode := debug
engine := 
precompiled := 
endif

engine := $(pwd/flutter)/bin/cache/artifacts/engine/$(platform)$(engine)
