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


source += $(wildcard $(pwd)/aleth/libdevcore/*.cpp)
source += $(wildcard $(pwd)/aleth/libp2p/*.cpp)

source += $(pwd)/aleth/libdevcrypto/Common.cpp
source += $(pwd)/aleth/libdevcrypto/CryptoPP.cpp

source += $(output)/$(pwd)/aleth/buildinfo.c

cflags += -I$(pwd)/aleth
cflags += -I$(pwd)/aleth/utils

cflags += -Wno-unknown-pragmas

source += $(pwd)/boost/libs/log/src/attribute_name.cpp
source += $(pwd)/boost/libs/log/src/attribute_set.cpp
source += $(pwd)/boost/libs/log/src/attribute_value_set.cpp
source += $(pwd)/boost/libs/log/src/core.cpp
source += $(pwd)/boost/libs/log/src/date_time_format_parser.cpp
source += $(pwd)/boost/libs/log/src/default_attribute_names.cpp
source += $(pwd)/boost/libs/log/src/default_sink.cpp
source += $(pwd)/boost/libs/log/src/dump.cpp
source += $(pwd)/boost/libs/log/src/exceptions.cpp
source += $(pwd)/boost/libs/log/src/global_logger_storage.cpp
source += $(pwd)/boost/libs/log/src/once_block.cpp
source += $(pwd)/boost/libs/log/src/record_ostream.cpp
source += $(pwd)/boost/libs/log/src/severity_level.cpp
source += $(pwd)/boost/libs/log/src/thread_id.cpp
source += $(pwd)/boost/libs/log/src/thread_specific.cpp

source += $(pwd)/boost/libs/thread/src/pthread/once_atomic.cpp
source += $(pwd)/boost/libs/thread/src/pthread/thread.cpp

#source += $(wildcard $(pwd)/cryptopp/*.cpp)

source += $(pwd)/cryptopp/algparam.cpp
source += $(pwd)/cryptopp/asn.cpp
source += $(pwd)/cryptopp/cpu.cpp
source += $(pwd)/cryptopp/cryptlib.cpp
source += $(pwd)/cryptopp/filters.cpp
source += $(pwd)/cryptopp/fips140.cpp
source += $(pwd)/cryptopp/hmac.cpp
source += $(pwd)/cryptopp/integer.cpp
source += $(pwd)/cryptopp/iterhash.cpp
source += $(pwd)/cryptopp/keccak.cpp
source += $(pwd)/cryptopp/misc.cpp
source += $(pwd)/cryptopp/modes.cpp
source += $(pwd)/cryptopp/queue.cpp
source += $(pwd)/cryptopp/rdtables.cpp
source += $(pwd)/cryptopp/rijndael.cpp
source += $(pwd)/cryptopp/sha.cpp

cflags_filters += -std=c++11
cflags += -Wno-unknown-warning-option
cflags += -DCRYPTOPP_EXPORTS
cflags += -DCRYPTOPP_MANUALLY_INSTANTIATE_TEMPLATES

cflags += -I$(pwd)/libff
cflags += -I$(pwd)/libff/libff
cflags += -I$(pwd)/libscrypt

cflags += -I$(pwd)/leveldb/include
cflags += -I$(pwd)/rocksdb/include
