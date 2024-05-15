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


w_jemalloc += --disable-cxx
w_jemalloc += --disable-libdl
w_jemalloc += --disable-stats
w_jemalloc += --disable-syscall
w_jemalloc += --enable-debug
w_jemalloc += --with-malloc-conf=tcache:false

w_jemalloc += ac_cv_func_sbrk=no
w_jemalloc += force_tls=0

jemalloc := lib/libjemalloc_pic.a
$(output)/%/$(pwd)/jemalloc/$(jemalloc): $(output)/%/$(pwd)/jemalloc/Makefile
	$(MAKE) -C $(dir $<) $(jemalloc)
linked += $(pwd)/jemalloc/$(jemalloc)
