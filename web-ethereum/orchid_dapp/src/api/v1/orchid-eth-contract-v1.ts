import {EthAddress} from "../orchid-eth-types";
import {getEthAddressParam} from "../../util/util";
import {AbiItem} from "web3-utils";

export class OrchidContractV1 {
  // TODO: Set to a reasonable number closer to deployment
  // The earliest block from which we look for events on chain for this contract.
  static startBlock: number = 0;
  static lottery_addr_final: EthAddress = '0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82';

  static lottery_addr(): EthAddress {
    return getEthAddressParam('lottery_addr', this.lottery_addr_final);
  }

  /// Indicates that one or more of the contract addresses have been overridden
  static contracts_overridden(): boolean {
    return this.lottery_addr() !== this.lottery_addr_final
  }

  static lottery_pull_amount_max_gas: number = 150000;
  static lottery_pull_all_max_gas: number = 150000;
  static lottery_lock_max_gas: number = 50000;
  static lottery_warn_max_gas: number = 50000;
  static lottery_move_max_gas: number = 175000;

  // Total max gas used by an add funds operation.
  static add_funds_total_max_gas: number = OrchidContractV1.lottery_move_max_gas;
  static stake_funds_total_max_gas: number = OrchidContractV1.add_funds_total_max_gas;

  static redeem_ticket_max_gas = 100000;

  static lottery_abi: AbiItem [] =
    [{
      "inputs": [{"internalType": "uint64", "name": "day", "type": "uint64"}],
      "stateMutability": "nonpayable",
      "type": "constructor"
    }, {
      "anonymous": false,
      "inputs": [{
        "indexed": true,
        "internalType": "contract IERC20",
        "name": "token",
        "type": "address"
      }, {
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
        "internalType": "bytes32",
        "name": "key",
        "type": "bytes32"
      }, {"indexed": false, "internalType": "uint256", "name": "unlock_warned", "type": "uint256"}],
      "name": "Delete",
      "type": "event"
    }, {
      "anonymous": false,
      "inputs": [{
        "indexed": true,
        "internalType": "address",
        "name": "funder",
        "type": "address"
      }, {"indexed": true, "internalType": "address", "name": "recipient", "type": "address"}],
      "name": "Enroll",
      "type": "event"
    }, {
      "anonymous": false,
      "inputs": [{
        "indexed": true,
        "internalType": "bytes32",
        "name": "key",
        "type": "bytes32"
      }, {"indexed": false, "internalType": "uint256", "name": "escrow_amount", "type": "uint256"}],
      "name": "Update",
      "type": "event"
    }, {
      "inputs": [{
        "internalType": "contract IERC20",
        "name": "token",
        "type": "address"
      }, {
        "internalType": "address",
        "name": "recipient",
        "type": "address"
      }, {
        "components": [{
          "internalType": "bytes32",
          "name": "data",
          "type": "bytes32"
        }, {
          "internalType": "bytes32",
          "name": "reveal",
          "type": "bytes32"
        }, {
          "internalType": "uint256",
          "name": "packed0",
          "type": "uint256"
        }, {
          "internalType": "uint256",
          "name": "packed1",
          "type": "uint256"
        }, {"internalType": "bytes32", "name": "r", "type": "bytes32"}, {
          "internalType": "bytes32",
          "name": "s",
          "type": "bytes32"
        }], "internalType": "struct OrchidLottery1.Ticket[]", "name": "tickets", "type": "tuple[]"
      }, {"internalType": "bytes32[]", "name": "refunds", "type": "bytes32[]"}],
      "name": "claim",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "inputs": [{
        "internalType": "contract IERC20",
        "name": "token",
        "type": "address"
      }, {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }, {
        "internalType": "address",
        "name": "signer",
        "type": "address"
      }, {"internalType": "int256", "name": "adjust", "type": "int256"}, {
        "internalType": "int256",
        "name": "warn",
        "type": "int256"
      }, {"internalType": "uint256", "name": "retrieve", "type": "uint256"}],
      "name": "edit",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "inputs": [{
        "internalType": "address",
        "name": "signer",
        "type": "address"
      }, {"internalType": "int256", "name": "adjust", "type": "int256"}, {
        "internalType": "int256",
        "name": "warn",
        "type": "int256"
      }, {"internalType": "uint256", "name": "retrieve", "type": "uint256"}],
      "name": "edit",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    }, {
      "inputs": [{
        "internalType": "bool",
        "name": "cancel",
        "type": "bool"
      }, {"internalType": "address[]", "name": "recipients", "type": "address[]"}],
      "name": "enroll",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "inputs": [{
        "internalType": "address",
        "name": "funder",
        "type": "address"
      }, {"internalType": "address", "name": "recipient", "type": "address"}],
      "name": "enrolled",
      "outputs": [{"internalType": "uint256", "name": "", "type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    }, {
      "inputs": [{
        "internalType": "contract IERC20",
        "name": "token",
        "type": "address"
      }, {
        "internalType": "address",
        "name": "signer",
        "type": "address"
      }, {"internalType": "uint64", "name": "marked", "type": "uint64"}],
      "name": "mark",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "inputs": [{
        "internalType": "address",
        "name": "sender",
        "type": "address"
      }, {"internalType": "uint256", "name": "amount", "type": "uint256"}, {
        "internalType": "bytes",
        "name": "data",
        "type": "bytes"
      }],
      "name": "onTokenTransfer",
      "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "inputs": [{
        "internalType": "contract IERC20",
        "name": "token",
        "type": "address"
      }, {
        "internalType": "address",
        "name": "funder",
        "type": "address"
      }, {"internalType": "address", "name": "signer", "type": "address"}],
      "name": "read",
      "outputs": [{
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }, {"internalType": "uint256", "name": "", "type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    }, {
      "inputs": [{
        "internalType": "uint256",
        "name": "count",
        "type": "uint256"
      }, {"internalType": "bytes32", "name": "seed", "type": "bytes32"}],
      "name": "save",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "inputs": [{
        "internalType": "address",
        "name": "sender",
        "type": "address"
      }, {"internalType": "uint256", "name": "amount", "type": "uint256"}, {
        "internalType": "bytes",
        "name": "data",
        "type": "bytes"
      }],
      "name": "tokenFallback",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }];

}