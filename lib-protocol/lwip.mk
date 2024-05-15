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


source += $(wildcard $(pwd)/lwip/src/api/*.c)
source += $(wildcard $(pwd)/lwip/src/core/*.c)
source += $(wildcard $(pwd)/lwip/src/core/ipv4/*.c)
source += $(wildcard $(pwd)/lwip/src/core/ipv6/*.c)
source += $(pwd)/lwip/src/netif/ethernet.c

ifeq ($(target),and)
cflags/$(pwd)/lwip/ += -Wno-missing-braces
endif

ifeq ($(target),win)
source += $(pwd)/lwip/contrib/ports/win32/sys_arch.c
cflags/$(pwd)/lwip/contrib/ports/win32/sys_arch.c += -UWIN32_LEAN_AND_MEAN
cflags += -I$(pwd)/lwip/contrib/ports/win32/include
else
source += $(pwd)/lwip/contrib/ports/unix/port/sys_arch.c
cflags += -I$(pwd)/lwip/contrib/ports/unix/port/include
endif

cflags += -I$(pwd)/lwip/src/include

cflags += -DLWIP_ERRNO_STDINCLUDE
cflags += -DLWIP_TCP

ifeq ($(target),lnx)
cflags += -DTCP_USER_TIMEOUT=18
endif
