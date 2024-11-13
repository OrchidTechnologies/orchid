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


source += $(filter-out \
    %_benchmark.cc \
    %_test.cc \
    %_test_common.cc \
    %_testing.cc \
    %/absl/hash/internal/print_hash_of.cc \
,$(foreach sub,base container crc debugging hash numeric profiling types strings synchronization time,$(wildcard $(pwd)/abseil-cpp/absl/$(sub)/*.cc $(pwd)/abseil-cpp/absl/$(sub)/internal/*.cc)) $(wildcard $(pwd)/abseil-cpp/absl/strings/internal/str_format/*.cc) $(wildcard $(pwd)/abseil-cpp/absl/time/internal/cctz/src/*.cc))

cflags += -I$(pwd)/abseil-cpp
