import {EthAddress} from "./orchid-types";
import { Contract } from "web3-eth-contract";
import {getEthAddressParam} from "../util/util";
import {AbiItem} from "web3-utils";

export class OrchidContracts {

  static token: Contract;
  static lottery: Contract;
  static directory: Contract;

  // TODO: We can get the token address from the lottery contract with `what()` now.
  static token_addr_final: EthAddress = '0x4575f41308EC1483f3d399aa9a2826d74Da13Deb'; // OXT Main net
  static token_addr(): EthAddress {
    return getEthAddressParam('token_addr', this.token_addr_final);
  }

  static lottery_addr_final: EthAddress = '0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1'; // Main net with OXT
  static lottery_addr(): EthAddress {
    return getEthAddressParam('lottery_addr', this.lottery_addr_final);
  }

  static directory_addr_final: EthAddress = '0x918101FB64f467414e9a785aF9566ae69C3e22C5'; // OXT Directory on main net
  static directory_addr(): EthAddress {
    return getEthAddressParam('directory_addr', this.directory_addr_final);
  }

  /// Indicates that one or more of the contract addresses have been overridden
  static contracts_overridden(): boolean {
    return this.token_addr() !== this.token_addr_final
      || this.lottery_addr() !== this.lottery_addr_final
      || this.directory_addr() !== this.directory_addr_final
  }

  static lottery_push_method_hash: string =
    '0x3cd5941d0d99319105eba5f5393ed93c883f132d251e56819e516005c5e20dbc'; // This is topic[0] of the push event.

  // TODO: Now that the contracts are final we can figure out the actual max gas these methods
  // TODO: can possibly consume, taking into account variation in storage allocation for new users.
  static token_approval_max_gas: number = 50000;
  static lottery_push_max_gas: number = 175000;
  static directory_push_max_gas: number = 300000;
  static lottery_pull_amount_max_gas: number = 150000;
  static lottery_pull_all_max_gas: number = 150000;
  static lottery_lock_max_gas: number = 50000;
  static lottery_warn_max_gas: number = 50000;
  static lottery_move_max_gas: number = 150000;

  // Total max gas used by an add funds operation.
  static add_funds_total_max_gas: number = OrchidContracts.token_approval_max_gas + OrchidContracts.lottery_push_max_gas;

  static stake_funds_total_max_gas: number = OrchidContracts.add_funds_total_max_gas;

  static token_abi: AbiItem [] = [
    {
      "inputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "constructor"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "owner",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "spender",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "value",
          "type": "uint256"
        }
      ],
      "name": "Approval",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "from",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "to",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "value",
          "type": "uint256"
        }
      ],
      "name": "Transfer",
      "type": "event"
    },
    {
      "constant": true,
      "inputs": [
        {
          "internalType": "address",
          "name": "owner",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "spender",
          "type": "address"
        }
      ],
      "name": "allowance",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {
          "internalType": "address",
          "name": "spender",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "approve",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [
        {
          "internalType": "address",
          "name": "account",
          "type": "address"
        }
      ],
      "name": "balanceOf",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [],
      "name": "decimals",
      "outputs": [
        {
          "internalType": "uint8",
          "name": "",
          "type": "uint8"
        }
      ],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {
          "internalType": "address",
          "name": "spender",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "subtractedValue",
          "type": "uint256"
        }
      ],
      "name": "decreaseAllowance",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {
          "internalType": "address",
          "name": "spender",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "addedValue",
          "type": "uint256"
        }
      ],
      "name": "increaseAllowance",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [],
      "name": "name",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        }
      ],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [],
      "name": "symbol",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        }
      ],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [],
      "name": "totalSupply",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {
          "internalType": "address",
          "name": "recipient",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "transfer",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {
          "internalType": "address",
          "name": "sender",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "recipient",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        }
      ],
      "name": "transferFrom",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ];

  static lottery_abi: AbiItem [] = [
    {
      "inputs": [{"internalType": "contract IERC20", "name": "token", "type": "address"}],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "constructor"
    }, {
      "anonymous": false,
      "inputs": [{
        "indexed": true,
        "internalType": "address",
        "name": "funder",
        "type": "address"
      }, {"indexed": true, "internalType": "address", "name": "signer", "type": "address"}],
      "name": "Bound",
      "type": "event"
    }, {
      "anonymous": false,
      "inputs": [{
        "indexed": true,
        "internalType": "address",
        "name": "funder",
        "type": "address"
      }, {"indexed": true, "internalType": "address", "name": "signer", "type": "address"}],
      "name": "Create",
      "type": "event"
    }, {
      "anonymous": false,
      "inputs": [{
        "indexed": true,
        "internalType": "address",
        "name": "funder",
        "type": "address"
      }, {
        "indexed": true,
        "internalType": "address",
        "name": "signer",
        "type": "address"
      }, {
        "indexed": false,
        "internalType": "uint128",
        "name": "amount",
        "type": "uint128"
      }, {
        "indexed": false,
        "internalType": "uint128",
        "name": "escrow",
        "type": "uint128"
      }, {"indexed": false, "internalType": "uint256", "name": "unlock", "type": "uint256"}],
      "name": "Update",
      "type": "event"
    }, {
      "constant": false,
      "inputs": [{
        "internalType": "address",
        "name": "signer",
        "type": "address"
      }, {
        "internalType": "contract OrchidVerifier",
        "name": "verify",
        "type": "address"
      }, {"internalType": "bytes", "name": "shared", "type": "bytes"}],
      "name": "bind",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "constant": false,
      "inputs": [{
        "internalType": "address",
        "name": "signer",
        "type": "address"
      }, {"internalType": "uint128", "name": "escrow", "type": "uint128"}],
      "name": "burn",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "constant": false,
      "inputs": [{
        "internalType": "address",
        "name": "funder",
        "type": "address"
      }, {
        "internalType": "address payable",
        "name": "recipient",
        "type": "address"
      }, {"internalType": "uint128", "name": "amount", "type": "uint128"}, {
        "internalType": "bytes",
        "name": "receipt",
        "type": "bytes"
      }],
      "name": "give",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "constant": false,
      "inputs": [{
        "internalType": "bytes32",
        "name": "reveal",
        "type": "bytes32"
      }, {
        "internalType": "bytes32",
        "name": "commit",
        "type": "bytes32"
      }, {
        "internalType": "uint256",
        "name": "issued",
        "type": "uint256"
      }, {"internalType": "bytes32", "name": "nonce", "type": "bytes32"}, {
        "internalType": "uint8",
        "name": "v",
        "type": "uint8"
      }, {"internalType": "bytes32", "name": "r", "type": "bytes32"}, {
        "internalType": "bytes32",
        "name": "s",
        "type": "bytes32"
      }, {
        "internalType": "uint128",
        "name": "amount",
        "type": "uint128"
      }, {
        "internalType": "uint128",
        "name": "ratio",
        "type": "uint128"
      }, {
        "internalType": "uint256",
        "name": "start",
        "type": "uint256"
      }, {
        "internalType": "uint128",
        "name": "range",
        "type": "uint128"
      }, {
        "internalType": "address",
        "name": "funder",
        "type": "address"
      }, {
        "internalType": "address payable",
        "name": "recipient",
        "type": "address"
      }, {
        "internalType": "bytes",
        "name": "receipt",
        "type": "bytes"
      }, {"internalType": "bytes32[]", "name": "old", "type": "bytes32[]"}],
      "name": "grab",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "constant": true,
      "inputs": [{"internalType": "address", "name": "funder", "type": "address"}],
      "name": "keys",
      "outputs": [{"internalType": "address[]", "name": "", "type": "address[]"}],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    }, {
      "constant": false,
      "inputs": [{"internalType": "address", "name": "signer", "type": "address"}],
      "name": "kill",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "constant": false,
      "inputs": [{"internalType": "address", "name": "signer", "type": "address"}],
      "name": "lock",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "constant": true,
      "inputs": [{
        "internalType": "address",
        "name": "funder",
        "type": "address"
      }, {"internalType": "address", "name": "signer", "type": "address"}],
      "name": "look",
      "outputs": [{
        "internalType": "uint128",
        "name": "",
        "type": "uint128"
      }, {"internalType": "uint128", "name": "", "type": "uint128"}, {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }, {
        "internalType": "contract OrchidVerifier",
        "name": "",
        "type": "address"
      }, {"internalType": "bytes32", "name": "", "type": "bytes32"}, {
        "internalType": "bytes",
        "name": "",
        "type": "bytes"
      }],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    }, {
      "constant": false,
      "inputs": [{
        "internalType": "address",
        "name": "signer",
        "type": "address"
      }, {"internalType": "uint128", "name": "amount", "type": "uint128"}],
      "name": "move",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "constant": true,
      "inputs": [{
        "internalType": "address",
        "name": "funder",
        "type": "address"
      }, {
        "internalType": "uint256",
        "name": "offset",
        "type": "uint256"
      }, {"internalType": "uint256", "name": "count", "type": "uint256"}],
      "name": "page",
      "outputs": [{"internalType": "address[]", "name": "", "type": "address[]"}],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    }, {
      "constant": false,
      "inputs": [{
        "internalType": "address",
        "name": "signer",
        "type": "address"
      }, {
        "internalType": "address payable",
        "name": "target",
        "type": "address"
      }, {"internalType": "bool", "name": "autolock", "type": "bool"}, {
        "internalType": "uint128",
        "name": "amount",
        "type": "uint128"
      }, {"internalType": "uint128", "name": "escrow", "type": "uint128"}],
      "name": "pull",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "constant": false,
      "inputs": [{
        "internalType": "address",
        "name": "signer",
        "type": "address"
      }, {
        "internalType": "uint128",
        "name": "total",
        "type": "uint128"
      }, {"internalType": "uint128", "name": "escrow", "type": "uint128"}],
      "name": "push",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "constant": false,
      "inputs": [{"internalType": "address payable", "name": "target", "type": "address"}],
      "name": "reset",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "constant": true,
      "inputs": [{
        "internalType": "address",
        "name": "funder",
        "type": "address"
      }, {"internalType": "uint256", "name": "offset", "type": "uint256"}],
      "name": "seek",
      "outputs": [{"internalType": "address", "name": "", "type": "address"}],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    }, {
      "constant": true,
      "inputs": [{"internalType": "address", "name": "funder", "type": "address"}],
      "name": "size",
      "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    }, {
      "constant": false,
      "inputs": [{"internalType": "address", "name": "signer", "type": "address"}],
      "name": "warn",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "constant": true,
      "inputs": [],
      "name": "what",
      "outputs": [{"internalType": "contract IERC20", "name": "", "type": "address"}],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    }, {
      "constant": false,
      "inputs": [{
        "internalType": "address",
        "name": "signer",
        "type": "address"
      }, {
        "internalType": "address payable",
        "name": "target",
        "type": "address"
      }, {"internalType": "bool", "name": "autolock", "type": "bool"}],
      "name": "yank",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ];

  static directory_abi: AbiItem [] = [
    {
      "inputs": [
        {
          "internalType": "contract IERC20",
          "name": "token",
          "type": "address"
        }
      ],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "constructor"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "stakee",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "staker",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint128",
          "name": "delay",
          "type": "uint128"
        }
      ],
      "name": "Delay",
      "type": "event"
    },
    {
      "anonymous": false,
      "inputs": [
        {
          "indexed": true,
          "internalType": "address",
          "name": "stakee",
          "type": "address"
        },
        {
          "indexed": true,
          "internalType": "address",
          "name": "staker",
          "type": "address"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "local",
          "type": "uint256"
        },
        {
          "indexed": false,
          "internalType": "uint256",
          "name": "global",
          "type": "uint256"
        }
      ],
      "name": "Update",
      "type": "event"
    },
    {
      "constant": true,
      "inputs": [],
      "name": "have",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [
        {
          "internalType": "address",
          "name": "stakee",
          "type": "address"
        }
      ],
      "name": "heft",
      "outputs": [
        {
          "internalType": "uint256",
          "name": "",
          "type": "uint256"
        }
      ],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [
        {
          "internalType": "address",
          "name": "staker",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "stakee",
          "type": "address"
        }
      ],
      "name": "name",
      "outputs": [
        {
          "internalType": "bytes32",
          "name": "",
          "type": "bytes32"
        }
      ],
      "payable": false,
      "stateMutability": "pure",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [
        {
          "internalType": "uint128",
          "name": "percent",
          "type": "uint128"
        }
      ],
      "name": "pick",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        },
        {
          "internalType": "uint128",
          "name": "",
          "type": "uint128"
        }
      ],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {
          "internalType": "address",
          "name": "stakee",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        },
        {
          "internalType": "uint256",
          "name": "index",
          "type": "uint256"
        }
      ],
      "name": "pull",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {
          "internalType": "address",
          "name": "stakee",
          "type": "address"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        },
        {
          "internalType": "uint128",
          "name": "delay",
          "type": "uint128"
        }
      ],
      "name": "push",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [
        {
          "internalType": "uint256",
          "name": "point",
          "type": "uint256"
        }
      ],
      "name": "seek",
      "outputs": [
        {
          "internalType": "address",
          "name": "",
          "type": "address"
        },
        {
          "internalType": "uint128",
          "name": "",
          "type": "uint128"
        }
      ],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {
          "internalType": "uint256",
          "name": "index",
          "type": "uint256"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        },
        {
          "internalType": "uint128",
          "name": "delay",
          "type": "uint128"
        }
      ],
      "name": "stop",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {
          "internalType": "uint256",
          "name": "index",
          "type": "uint256"
        },
        {
          "internalType": "uint256",
          "name": "amount",
          "type": "uint256"
        },
        {
          "internalType": "address payable",
          "name": "target",
          "type": "address"
        }
      ],
      "name": "take",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {
          "internalType": "address",
          "name": "stakee",
          "type": "address"
        },
        {
          "internalType": "uint128",
          "name": "delay",
          "type": "uint128"
        }
      ],
      "name": "wait",
      "outputs": [],
      "payable": false,
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [],
      "name": "what",
      "outputs": [
        {
          "internalType": "contract IERC20",
          "name": "",
          "type": "address"
        }
      ],
      "payable": false,
      "stateMutability": "view",
      "type": "function"
    }
  ];

}

