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


assemble := linux
platform := linux-x64

generated := $(pwd/gui)/$(assemble)/flutter/generated_plugin_registrant%cc

debug += noaot

include $(pwd)/target-cpp.mk

cflags += -I$(pwd)/engine/shell/platform/$(assemble)/public
cflags += -I$(pwd)/engine/shell/platform/common/cpp/public

lflags += $(engine)/libflutter_linux_gtk.so

$(output)/package/libflutter_linux_gtk.so: $(engine)/libflutter_linux_gtk.so
	@mkdir -p $(dir $@)
	cp -f $< $@
	@chmod 644 $@
signed += $(output)/package/libflutter_linux_gtk.so
