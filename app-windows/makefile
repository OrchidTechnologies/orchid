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


target := win
include env/target.mk

signed := 

.PHONY: all
all: $(output)/$(name).zip

source += $(wildcard $(pwd)/source/*.cpp)
source += $(wildcard $(pwd)/source/*.rc)

$(call include,shared/target-win.mk)

include env/output.mk

$(output)/package/$(name)$(exe): $(patsubst %,$(output)/$(default)/%,$(object) $(linked))
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@set -o pipefail; $(cxx) $(more/$(default)) -Wl,-subsystem,windows $(wflags) -o $@ $(filter %.o,$^) $(filter %.a,$^) $(filter %.lib,$^) $(lflags) 2>&1 -Wl,-v | nl
	@openssl sha256 -r $@
	@ls -la $@
signed += $(output)/package/$(name)$(exe)

$(output)/$(name).zip: $(signed)
	@rm -f $@
	cd $(output)/package && zip -rXy $(zflags) ../$(name).zip *
