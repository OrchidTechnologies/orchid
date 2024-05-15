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


args := 

distro := ubuntu jammy 11
crypto := boringssl
include env/target.mk

binary := $(output)/$(machine)/worker$(exe)

.PHONY: all
all: $(binary)

.PHONY: debug
debug: $(binary)
	lldb -o 'b malloc_error_break' -o 'run $(args)' $<

.PHONY: test
test: $(binary)
	strace -ff -e 'trace=!write' $< 2>&1 | ./syscalls.sh

source += $(wildcard $(pwd)/source/*.cpp)
source += $(pwd)/libc.cpp

cflags += -I$(pwd)/source

lflags += -static-pie
cflags += -ftls-model=local-exec
lflags := $(filter-out -pthread,$(lflags))

cflags/$(pwd)/source/main.cpp += -Wno-deprecated-enum-enum-conversion

cflags += -I$(pwd)/extra
$(call include,cv8/target.mk)

$(call include,lib/target.mk)

# XXX: I might not need this anymore
cflags += -D_LIBCPP_HAS_NO_STDIN=

# XXX: I might not need this anymore
w_icu4c += ac_cv_var_timezone=no
w_icu4c += ac_cv_var___timezone=no
w_icu4c += ac_cv_var_tzname=no
w_icu4c += ac_cv_var__tzname=no
w_icu4c += ac_cv_func_tzset=no

include jemalloc.mk

include capnproto.mk

cflags += -I$(pwd)/workerd/src
cflags += -I$(output)/capnp/workerd/src
#source += $(filter-out %-test.c++,$(wildcard $(pwd)/workerd/src/workerd/api/crypto-impl-*.c++))

header += $(output)/capnp/$(pwd)/capnproto/c++/src/capnp/compat/byte-stream.capnp.h
header += $(output)/capnp/$(pwd)/capnproto/c++/src/capnp/compat/http-over-capnp.capnp.h

header += $(output)/capnp/$(pwd)/workerd/src/workerd/io/actor-storage.capnp.h
header += $(output)/capnp/$(pwd)/workerd/src/workerd/io/compatibility-date.capnp.h
header += $(output)/capnp/$(pwd)/workerd/src/workerd/io/outcome.capnp.h
header += $(output)/capnp/$(pwd)/workerd/src/workerd/io/script-version.capnp.h
header += $(output)/capnp/$(pwd)/workerd/src/workerd/io/worker-interface.capnp.h

header += $(output)/capnp/$(pwd)/workerd/src/workerd/jsg/modules.capnp.h

include env/output.mk

$(output)/%/worker$(exe): $(patsubst %,$(output)/$$*/%,$(object) $(linked))
	@mkdir -p $(dir $@)
	@echo [LD] $@
	@$(cxx) $(more/$*) $(wflags) -o $@ $^ $(lflags) -Wl,--color-diagnostics=always -fcolor-diagnostics 2>&1 | nl
	@openssl sha256 -r $@
	@ls -la $@
