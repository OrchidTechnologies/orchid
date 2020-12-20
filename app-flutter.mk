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

include ../env/common.mk
pwd/gui := ./gui
$(call include,shared/target-all.mk)

$(foreach fork,$(forks),$(shell ln -sf $(patsubst %/pubspec.yaml,%,$(fork)) >/dev/null))

.PHONY: create
create: $(pwd/flutter)/packages/flutter/pubspec.lock
	$(flutter) create -i objc -a java --no-pub --project-name orchid .

builds := 
builds += apk
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
