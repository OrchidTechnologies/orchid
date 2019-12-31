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


boost := 
boost += algorithm
boost += any
boost += array
boost += asio
boost += assert
boost += beast
boost += bind
boost += concept_check
boost += config
boost += container
boost += container_hash
boost += core
boost += date_time
boost += detail
boost += endian
boost += filesystem
boost += function
boost += integer
boost += intrusive
boost += io
boost += iterator
boost += lexical_cast
boost += logic
boost += math
boost += move
boost += mp11
boost += mpl
boost += multiprecision
boost += optional
boost += predef
boost += preprocessor
boost += program_options
boost += random
boost += range
boost += rational
boost += regex
boost += smart_ptr
boost += static_assert
boost += system
boost += throw_exception
boost += tokenizer
boost += type_index
boost += type_traits
boost += utility
boost += winapi
cflags += $(patsubst %,-I$(pwd)/boost/libs/%/include,$(boost))

cflags += $(patsubst %,-I%,$(wildcard $(pwd)/boost/libs/numeric/*/include))
cflags += -I$(pwd)/boost/libs/asio/include/boost
cflags += -DBOOST_ASIO_DISABLE_CONNECTEX
