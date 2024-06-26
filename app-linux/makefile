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


target := lnx
distro := ubuntu bionic 7 libgtk-3-dev
include env/target.mk

signed := 

.PHONY: all
all: $(output)/$(name).tgz

.PHONY: app
app: $(signed)

source += $(wildcard $(pwd)/source/*.cpp)

cflags/$(pwd)/source/main.cpp += -Wno-unused-function
checks/$(pwd)/source/main.cpp += -bugprone-assignment-in-if-condition
checks/$(pwd)/source/main.cpp += -clang-diagnostic-unused-function
checks/$(pwd)/source/main.cpp += -cppcoreguidelines-pro-type-cstyle-cast
checks/$(pwd)/source/main.cpp += -cppcoreguidelines-pro-type-member-init
checks/$(pwd)/source/main.cpp += -cppcoreguidelines-pro-type-vararg
checks/$(pwd)/source/main.cpp += -misc-const-correctness
checks/$(pwd)/source/main.cpp += -misc-use-anonymous-namespace

$(call include,shared/target-lnx.mk)

include env/output.mk

includes := 
includes += atk-1.0
includes += cairo
includes += gdk-pixbuf-2.0
includes += glib-2.0
includes += gtk-3.0
includes += pango-1.0

cflags += $(patsubst %,-I$(output)/sysroot/usr/include/%,$(includes))
cflags += -I$(output)/sysroot/usr/lib/$(host/x86_64)/glib-2.0/include

lflags += $(output)/sysroot/usr/lib/$(host/x86_64)/libgdk-3.so
lflags += $(output)/sysroot/usr/lib/$(host/x86_64)/libglib-2.0.so
lflags += $(output)/sysroot/usr/lib/$(host/x86_64)/libgtk-3.so
lflags += $(output)/sysroot/usr/lib/$(host/x86_64)/libgio-2.0.so
lflags += $(output)/sysroot/usr/lib/$(host/x86_64)/libgobject-2.0.so

shareds := $(pwd/gui)/linux/flutter/ephemeral/.plugin_symlinks/*/linux/shared
$(output)/package/lib/%: $$(wildcard $(shareds)/%)
	@mkdir -p $(dir $@)
	cp -af $< $@
signed += $(patsubst %,$(output)/package/lib/%,$(notdir $(wildcard $(shareds)/*.so)))

$(output)/package/$(name)$(exe): $(patsubst %,$(output)/$(machine)/%,$(object) $(linked))
	@echo [LD] $@
	@set -o pipefail; $(cxx) $(more/$(machine)) $(wflags) -o $@ $(filter %.o,$^) $(filter %.a,$^) $(filter %.lib,$^) $(lflags) -Wl,-rpath,'$$ORIGIN' 2>&1 | nl
	@openssl sha256 -r $@
	@ls -la $@
signed += $(output)/package/$(name)$(exe)

$(output)/$(name).tgz: $(signed)
	@rm -f $@
	cd $(output)/package && tar -zcvf ../$(name).tgz .

.PHONY: test
test: $(signed)
	xdotool windowkill "$$(i3-msg -t get_tree | jq 'recurse(.nodes[]?)|select(.name=="Orchid")|.window')"
	i3-msg "append_layout ${PWD}/i3layout.json"
	$(output)/package/$(name)$(exe)
