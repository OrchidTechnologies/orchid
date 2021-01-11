import {EthAddress} from "../orchid-eth-types";
import {getEthAddressParam} from "../../util/util";
import {AbiItem} from "web3-utils";

export class OrchidContractV1 {
  // TODO: Set to a reasonable number closer to deployment
  // The earliest block from which we look for events on chain for this contract.
  static startBlock: number = 0;

  static lottery_addr_final: EthAddress = '0x49D600B34718387cE42FFC00eA3042218e453B23';

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

  static lottery_abi: AbiItem [] = [
    {
      "anonymous": false,
      "inputs": [{"indexed": true, "internalType": "address", "name": "funder", "type": "address"}],
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
      }, {"indexed": true, "internalType": "address", "name": "signer", "type": "address"}],
      "name": "Delete",
      "type": "event"
    }, {
      "anonymous": false,
      "inputs": [{
        "indexed": true,
        "internalType": "address",
        "name": "funder",
        "type": "address"
      }, {"indexed": true, "internalType": "address", "name": "signer", "type": "address"}],
      "name": "Update",
      "type": "event"
    }, {
      "inputs": [{
        "internalType": "bool",
        "name": "allow",
        "type": "bool"
      }, {"internalType": "address[]", "name": "recipients", "type": "address[]"}],
      "name": "bind",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }, {
      "inputs": [{
        "internalType": "bytes32",
        "name": "refund",
        "type": "bytes32"
      }, {
        "internalType": "uint256",
        "name": "destination",
        "type": "uint256"
      }, {
        "components": [{
          "internalType": "uint256",
          "name": "packed0",
          "type": "uint256"
        }, {
          "internalType": "uint256",
          "name": "packed1",
          "type": "uint256"
        }, {
          "internalType": "uint256",
          "name": "packed2",
          "type": "uint256"
        }, {"internalType": "bytes32", "name": "r", "type": "bytes32"}, {
          "internalType": "bytes32",
          "name": "s",
          "type": "bytes32"
        }], "internalType": "struct OrchidLottery1eth.Ticket", "name": "ticket", "type": "tuple"
      }], "name": "claim1", "outputs": [], "stateMutability": "nonpayable", "type": "function"
    }, {
      "inputs": [{
        "internalType": "bytes32[]",
        "name": "refunds",
        "type": "bytes32[]"
      }, {
        "internalType": "uint256",
        "name": "destination",
        "type": "uint256"
      }, {
        "components": [{
          "internalType": "uint256",
          "name": "packed0",
          "type": "uint256"
        }, {
          "internalType": "uint256",
          "name": "packed1",
          "type": "uint256"
        }, {
          "internalType": "uint256",
          "name": "packed2",
          "type": "uint256"
        }, {"internalType": "bytes32", "name": "r", "type": "bytes32"}, {
          "internalType": "bytes32",
          "name": "s",
          "type": "bytes32"
        }],
        "internalType": "struct OrchidLottery1eth.Ticket[]",
        "name": "tickets",
        "type": "tuple[]"
      }], "name": "claimN", "outputs": [], "stateMutability": "nonpayable", "type": "function"
    }, {
      "inputs": [{
        "internalType": "address",
        "name": "funder",
        "type": "address"
      }, {"internalType": "address", "name": "signer", "type": "address"}],
      "name": "gift",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    }, {
      "inputs": [{
        "internalType": "address",
        "name": "signer",
        "type": "address"
      }, {"internalType": "uint256", "name": "adjust_retrieve", "type": "uint256"}],
      "name": "move",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    }, {
      "inputs": [{
        "internalType": "address",
        "name": "funder",
        "type": "address"
      }, {
        "internalType": "address",
        "name": "signer",
        "type": "address"
      }, {"internalType": "address", "name": "recipient", "type": "address"}],
      "name": "read",
      "outputs": [{
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }, {"internalType": "uint256", "name": "", "type": "uint256"}, {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }],
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
        "name": "signer",
        "type": "address"
      }, {"internalType": "uint128", "name": "warned", "type": "uint128"}],
      "name": "warn",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    //{"stateMutability": "payable", "type": "receive"}
  ];

}