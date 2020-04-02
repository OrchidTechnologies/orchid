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


flutter := flutter/bin/flutter --suppress-analytics --verbose

flutter/packages/flutter/pubspec.lock: flutter/packages/flutter/pubspec.yaml $(call head,flutter)
	cd flutter && git clean -fxd
	cd flutter && bin/flutter precache --macos
	cd flutter && bin/flutter update-packages

pubspec%lock %flutter-plugins %packages: pubspec.yaml
	mkdir -p $(assemble)
	$(flutter) pub get

ifeq ($(filter noaot,$(debug)),)
mode := release
engine := -release
precompiled := --precompiled
else
mode := debug
engine := 
precompiled := 
endif

engine := flutter/bin/cache/artifacts/engine/$(platform)$(engine)

dart := $(shell find lib/ -name '*.dart')
dart += flutter/packages/flutter/pubspec.lock
dart += pubspec.lock
dart += .flutter-plugins
dart += .packages
