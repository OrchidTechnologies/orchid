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


#args += --currency WAVAX,0x00c6a247a868dee7e84d16eba22d1ab903108a44
#args += --currency WBNB,0xba8080b0b09181e09bca0612b22b9475d8171055
#args += --currency WBTC,0x4585fe77225b41b697c938b018e2ac67ac5a20c0
#args += --currency DAI,0x60594a405d53811d3bc4766596efd80fd545a270
#args += --currency FTM,0x3b685307c8611afb2a9e83ebc8743dc20480716e
#args += --currency MATIC,0x290a6a7460b308ee3f19023d2d00de604bcf5b42
#args += --currency OXT,0x820e5ab3d952901165f858703ae968e5ea67eb31
#args += --currency TLOS,0x27dd7b7d610c9be6620a893b51d0f7856c6f3bfd

args += --chain 1,ETH,https://cloudflare-eth.com/
args += --chain 10,ETH,https://mainnet.optimism.io/
args += --chain 30,BTC,https://public-node.rsk.co/
#args += --chain 40,TLOS,https://mainnet.telos.net/evm
args += --chain 56,BNB,https://bsc-dataseed.binance.org/
args += --chain 100,DAI,https://rpc.xdaichain.com/
args += --chain 137,MATIC,https://polygon-rpc.com/
#args += --chain 200,DAI,https://arbitrum.xdaichain.com/
args += --chain 250,FTM,https://rpc.ftm.tools/
#args += --chain 42161,ETH,https://arb1.arbitrum.io/rpc
# https://github.com/celo-org/celo-blockchain/issues/1734
# https://github.com/celo-org/celo-blockchain/issues/1737
#args += --chain 42220,CELO,https://forno.celo.org/
args += --chain 43114,AVAX,https://api.avax.network/ext/bc/C/rpc
args += --chain 1313161554,ETH,https://mainnet.aurora.dev/
