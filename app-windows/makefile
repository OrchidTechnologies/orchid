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


target := win
include env/target.mk

signed := 

.PHONY: all
all: $(output)/$(machine)/$(name).msix

source += $(wildcard $(pwd)/source/*.cpp)
source += $(wildcard $(pwd)/source/*.rc)

$(call include,shared/target-win.mk)

include env/output.mk

makemsix := msix-packaging/.vs/bin/makemsix

package := $(output)/$(machine)/package

$(makemsix):
	@cd msix-packaging && ./makelinux.sh --pack --skip-samples --skip-tests

$(package)/$(name)$(exe): $(patsubst %,$(output)/$(machine)/%,$(object) $(linked))
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@set -o pipefail; $(cxx) $(more/$(machine)) -Wl,-subsystem,windows $(wflags) -o $@ $(filter %.o,$^) $(filter %.a,$^) $(filter %.lib,$^) $(lflags) 2>&1 -Wl,-v | nl
	@openssl sha256 -r $@
	@ls -la $@
signed += $(package)/$(name)$(exe)

$(output)/$(machine)/package.wxs: $(signed)
	find $(package)/ | wixl-heat --prefix $(package)/ --directory-ref INSTALLDIR --component-group $(name) --var var.package >$@

$(output)/$(machine)/$(name).msi: orchid.wxs $(output)/$(machine)/package.wxs
	@rm -f $@
	wixl -v -a x64 $^ -o $@ -D name=$(name) -D package=$(package) -D guid=$(guid) -D version=$(version)

$(package)/AppxManifest.xml: AppxManifest.xml.in
	@mkdir -p $(dir $@)
	$(replace)

$(output)/$(machine)/$(name).msix: $(package)/AppxManifest.xml $(makemsix) $(signed)
	$(makemsix) pack -d $(package) -p $@
