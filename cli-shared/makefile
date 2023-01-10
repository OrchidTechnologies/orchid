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


args := --config ../orchid.cfg

# XXX: decide whether to give up on old CentOS or follow this issue
# https://gitlab.gnome.org/GNOME/glib/-/issues/2861
# https://gitlab.gnome.org/GNOME/glib/-/merge_requests/3120#note_1627293
distro := ubuntu bionic
include env/target.mk

version := 0.9

.PHONY: all
all: $(output)/$(machine)/orchidcd$(exe)

.PHONY: test
test: $(output)/$(machine)/orchidcd$(exe)
	sudo $< $(args)

.PHONY: leak
leak: $(output)/$(machine)/orchidcd$(exe)
	sudo bash -c 'MallocStackLogging=1 $< $(args)'

.PHONY: debug
debug: $(output)/$(machine)/orchidcd$(exe)
	sudo lldb -o 'b malloc_error_break' -o 'run $(args)' $<

$(call include,vpn/target.mk)

ifeq ($(target),mac)
cflags += -Iall/vpn-apple/source
source += all/vpn-apple/source/protect.cpp
source += all/vpn-apple/source/tunnel.cpp
endif
ifeq ($(target),win)
source += all/vpn-windows/source/protect.cpp
source += all/vpn-windows/source/tunnel.cpp
cflags += -Iall/vpn-windows/source
endif
ifeq ($(target),lnx)
cflags += -Iall/vpn-linux/source
source += all/vpn-linux/source/protect.cpp
source += all/vpn-linux/source/tunnel.cpp
endif

source += $(wildcard source/*.cpp)

cflags += -DORC_FIBER

# XXX: this was a mistake
cflags += -DGUI_orchid

ifeq ($(target),lnx)
lflags += -static
endif

include env/output.mk

$(output)/%/orchidcd$(exe): $(patsubst %,$(output)/$$*/%,$(object) $(linked))
	@echo [LD] $@
	@set -o pipefail; $(cxx) $(more/$*) $(wflags) -o $@ $(filter %.o,$^) $(filter %.a,$^) $(filter %.lib,$^) $(lflags) 2>&1 | nl
	@openssl sha256 -r $@
	@ls -la $@
ifeq ($(target),mac)
	@otool -lah $@ | grep '^  s.*__DATA' -A8 -B2
endif
