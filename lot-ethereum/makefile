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


include env/common.mk

.PHONY: all
all:

build/OrchidVerifier.bin: verifier.sol
	@mkdir -p $(dir $@)
	env/solc.sh 0.7.2 build verifier.sol --evm-version homestead
all += build/OrchidVerifier.bin

build/OrchidLottery0.bin: lottery0.sol
	@mkdir -p $(dir $@)
	env/solc.sh 0.5.13 build lottery0.sol --evm-version istanbul
all += build/OrchidLottery0.bin

build/OrchidLottery1eth.bin: lottery1.sol
	@mkdir -p $(dir $@)
	cpp -C -P lottery1.sol >lottery1-eth.sol
	env/solc.sh 0.7.2 build lottery1-eth.sol --evm-version istanbul --optimize --optimize-runs 10000
all += build/OrchidLottery1eth.bin

build/OrchidLottery1tok.bin: lottery1.sol
	@mkdir -p $(dir $@)
	cpp -C -P lottery1.sol >lottery1-tok.sol -DORC_SYM=
	env/solc.sh 0.7.2 build lottery1-tok.sol --evm-version istanbul --optimize --optimize-runs 10000
all += build/OrchidLottery1tok.bin

build/OrchidLottery1oxt.bin: lottery1.sol
	@mkdir -p $(dir $@)
	cpp -C -P lottery1.sol >lottery1-oxt.sol -DORC_SYM=oxt -DORC_ERC=0x4575f41308EC1483f3d399aa9a2826d74Da13Deb
	env/solc.sh 0.7.2 build lottery1-oxt.sol --evm-version istanbul --optimize --optimize-runs 10000
all += build/OrchidLottery1oxt.bin

build/OrchidRecipient.bin: recipient.yul
	@mkdir -p $(dir $@)
	env/solc.sh 0.7.2 - recipient.yul --strict-assembly | tee /dev/stderr | sed -e '/^Binary/{x;N;p};d' | tr -d $$'\n' >$@
all += build/OrchidRecipient.bin

all: $(all)
