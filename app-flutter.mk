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


.PHONY: all
all: 

include ./env/common.mk
pwd/gui := ./gui
$(call include,shared/target-all.mk)

$(foreach fork,$(forks),$(shell ln -sf $(patsubst %/pubspec.yaml,%,$(fork)) >/dev/null))

sed := $(shell which gsed sed | head -n1)

.PHONY: create
create: $(pwd/flutter)/packages/flutter/pubspec.lock
	$(flutter) create -i objc -a java --no-pub --project-name orchid .
	$(flutter) pub get
	$(sed) -ie 's/flutter\.compileSdkVersion/34/g;s/flutter.minSdkVersion/21/g' android/app/build.gradle
	$(sed) -ie '0,/subprojects {/s//\0 afterEvaluate { android { compileSdkVersion 34 } }/' android/build.gradle
	$(sed) -ie '/org\.jetbrains\.kotlin\.android/s/\(version "\)[^"]*/\11.8.0/' android/settings.gradle
	$(sed) -ie "/^# platform :ios/{s/^# //;}" ios/Podfile
	$(sed) -ie "/^platform :osx/{s/,.*/, '10.15'/;}" macos/Podfile
	$(sed) -ie "/MACOSX_DEPLOYMENT_TARGET =/{s/=.*/= 10.15;/g;}" macos/Runner.xcodeproj/project.pbxproj

builds := 
builds += apk
# XXX: I need to filter based on uname :/
#builds += linux
builds += macos
builds += ios

define all
.PHONY: $(1)
$(1): $$(forks) $$(dart)
	$$(flutter) build $(1) $(if $(filter $(1),ios),|| true)
all: $(1)
endef

$(foreach build,$(builds),$(eval $(call all,$(build))))

.PHONY: test
test: $(forks)
	$(flutter) run

.PHONY: run
run:
	while [[ 1 ]]; do make test; done
