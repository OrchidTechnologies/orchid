#!/bin/bash

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

set -e
set -o pipefail

runs=4294967295

env/solc.sh 0.7.2 build verifier.sol --abi --evm-version homestead
env/solc.sh 0.5.13 build lottery0.sol --abi --evm-version istanbul
env/solc.sh 0.7.6 build seller1.sol --abi --evm-version istanbul --optimize --optimize-runs "${runs}"
#env/solc.sh 0.7.2 - recipient.yul --strict-assembly | tee /dev/stderr | sed -e '/^Binary/{x;N;p};d' | tr -d $$'\n' >build/OrchidRecipient.bin
