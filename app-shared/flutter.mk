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


flutter/packages/flutter/pubspec.lock: flutter/packages/flutter/pubspec.yaml ../.git/modules/flutter/HEAD
	cd flutter && git clean -fxd
	cd flutter && bin/flutter precache
	cd flutter && bin/flutter update-packages

pubspec.lock: pubspec.yaml
	flutter/bin/flutter pub get

ifeq ($(filter noaot,$(debug)),)
mode := release
engine := -release
precompiled := --precompiled
else
mode := debug
engine := 
precompiled := 
endif

dart := $(shell find lib/ -name '*.dart')
dart += pubspec.lock
dart += pubspec.yaml
dart += flutter/packages/flutter/pubspec.yaml
