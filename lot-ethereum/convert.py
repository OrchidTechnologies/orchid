#!/usr/bin/env python3
import json
open('build/lottery.json', 'w').write(json.dumps({"language":"Solidity","sources":{"lottery.sol":{"content":open('lottery.sol').read()}},"settings":{"evmVersion":"istanbul"}}))
