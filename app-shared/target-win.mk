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


assemble := windows
platform := windows-x64

generated := $(pwd/gui)/$(assemble)/flutter/generated_plugin_registrant%cc

debug += noaot

include $(pwd)/target-cpp.mk

source += $(wildcard $(template)/runner/*.cpp)
cflags += -I$(template)/runner

source += $(filter-out %_unittests.cc,$(wildcard $(pwd)/engine/shell/platform/windows/client_wrapper/*.cc))
cflags += -I$(pwd)/engine/shell/platform/windows/client_wrapper/include
cflags += -I$(pwd)/engine/shell/platform/common/cpp/client_wrapper{,/include{,/flutter}}

cflags += -I$(pwd)/engine/shell/platform/windows/public
cflags += -I$(pwd)/engine/shell/platform/common/cpp/public

cflags/$(pwd/gui)/ += -UWIN32_LEAN_AND_MEAN
cflags/$(pwd)/ += -UWIN32_LEAN_AND_MEAN

cflags/$(pwd/gui)/ += -DUNICODE
cflags/$(pwd)/ += -DUNICODE

lflags += -municode

lflags += $(engine)/flutter_windows.dll.lib
lflags += -lole32

$(output)/package/flutter_windows.dll: $(engine)/flutter_windows.dll
	@mkdir -p $(dir $@)
	cp -f $< $@
signed += $(output)/package/flutter_windows.dll

# XXX: compile manifest into the executable
$(output)/package/$(name)$(exe).manifest: $(template)/runner/runner.exe.manifest
	@mkdir -p $(dir $@)
	cp -f $< $@
signed += $(output)/package/$(name)$(exe).manifest
