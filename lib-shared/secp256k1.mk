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


pwd/secp256k1 := $(pwd)/secp256k1
source += $(pwd/secp256k1)/src/secp256k1.c
source += $(pwd/secp256k1)/src/precomputed_ecmult.c
source += $(pwd/secp256k1)/src/precomputed_ecmult_gen.c
cflags += -I$(pwd/secp256k1)/include

cflags/$(pwd/secp256k1)/ += -I$(pwd/secp256k1)
cflags/$(pwd/secp256k1)/ += -I$(pwd/secp256k1)/src
cflags/$(pwd/secp256k1)/ += -Wno-unused-function

cflags += -DSECP256K1_STATIC

cflags += -DENABLE_MODULE_RECOVERY
cflags += -DENABLE_MODULE_ECDH
cflags += -DECMULT_WINDOW_SIZE=15
cflags += -DECMULT_GEN_PREC_BITS=4
