import {Address} from "./orchid-types";
import {OrchidContracts} from "./orchid-eth-contracts";

const BigInt = require("big-integer"); // Mobile Safari requires polyfill

export class EtherscanIO {
  apiKey: string = "73BIQR3R1ER56V53PSSAPNUTQUFVHCVVVH";
  api_url: string = 'https://api.etherscan.io/api';
  lotteryContractAddress: Address = OrchidContracts.lottery_addr();
  lotteryFundMethodHash: string = OrchidContracts.lottery_push_method_hash;
  startBlock: number = 872000;

  /*
    Get lottery pot funding events for the specified address in descending
    time order (most recent first).

    Example JSON:

     https://api.etherscan.io/api
      ?module=logs
      &action=getLogs
      &fromBlock=8000000&toBlock=latest
      &address=0xd4779b223797ecb6b8833f6f1545f2d94b29219c
      &topic0=0xd6baf52d1a5fcdfc28f52cd8c2b20065e3d2d5354c0384fd85377ad6ae54493d
      &topic1=0x000000000000000000000000accd85a8b3f96cccde5e741fd35ea761cba3f621
      &apikey=73BIQR3R1ER56V53PSSAPNUTQUFVHCVVVH

    {
    "status": "1",
    "message": "OK",
    "result": [
      {
        "address": "0xd4779b223797ecb6b8833f6f1545f2d94b29219c",
        "topics": [
          "0xd6baf52d1a5fcdfc28f52cd8c2b20065e3d2d5354c0384fd85377ad6ae54493d",
          "0x000000000000000000000000accd85a8b3f96cccde5e741fd35ea761cba3f621"
        ],
        "data": "0x0000000000000000000000000000000000000000000000001bc16d674ec8000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "blockNumber": "0x7d3075",
        "timeStamp": "0x5d36789f",
        "gasPrice": "0x3b9aca00",
        "gasUsed": "0xee44",
        "logIndex": "0xa0",
        "transactionHash": "0x52f6cc0170da633acb9bb0c58265434700ac371df09688175936e6922acc821e",
        "transactionIndex": "0x99"
      },
      {
        "address": "0xd4779b223797ecb6b8833f6f1545f2d94b29219c",
        "topics": [
          "0xd6baf52d1a5fcdfc28f52cd8c2b20065e3d2d5354c0384fd85377ad6ae54493d",
          "0x000000000000000000000000accd85a8b3f96cccde5e741fd35ea761cba3f621"
        ],
        "data": "0x0000000000000000000000000000000000000000000000004563918244f4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "blockNumber": "0x7d3db4",
        "timeStamp": "0x5d372ac4",
        "gasPrice": "0x3b9aca00",
        "gasUsed": "0xb3ac",
        "logIndex": "0xe1",
        "transactionHash": "0xd42a7d8d76b6a9aa7a601228244a46766aee7fc35ddab1eb1537aee894fc8d83",
        "transactionIndex": "0x42"
      }
    ]
    }
  */
  async getEvents(funder: Address, signer: Address): Promise<LotteryPotUpdateEvent[]> {
    let url = new URL(this.api_url);
    let params: { [index: string]: string } = {
      'module': 'logs',
      'action': 'getLogs',
      'fromBlock': this.startBlock.toString(),
      'toBlock': 'latest',
      'address': this.lotteryContractAddress,
      'topic0': this.lotteryFundMethodHash,
      'topic0_1_opr': 'and',
      'topic1': EtherscanIO.pad64Chars(funder),
      'topic1_2_opr': 'and',
      'topic2': EtherscanIO.pad64Chars(signer),
      'apikey': this.apiKey
    };
    Object.keys(params).forEach(key => url.searchParams.append(key, params[key]));
    const response: Response = await fetch(url.toString());
    if (response.status !== 200) {
      console.log(`Error status code: ${response.status}`);
      throw new Error();
    }
    const json = await response.json();

    if (json['message'] === "No records found") {
      return [];
    }
    if (json['message'] !== "OK") {
      console.log(`Error message: ${json['message']}`);
      throw new Error();
    }
    let result = json['result'];

    let list: LotteryPotUpdateEvent[] = result.map((ev: any) => {
      // The first 64char hex data field is the balance
      let start = 2;
      let end = start + 64;
      // polyfill big-integer does not accept a 0x prefix for hex.
      const balanceStr = ev['data'].toString().substring(start, end);
      let balance = BigInt(0);
      try {
        balance = BigInt(balanceStr, 16);
      } catch (err) {
        throw new Error("invalid response data: " + balanceStr);
      }

      // The second 64char hex data field is the escrow
      start += 64;
      end += 64;
      let escrow = BigInt(0);
      try {
        escrow = BigInt(ev['data'].toString().substring(start, end), 16);
      } catch (err) {
        throw new Error("invalid response data");
      }

      // ETH timestamp is seconds since epoch
      const timeStamp = new Date(parseInt(ev['timeStamp']) * 1000);

      return new LotteryPotUpdateEvent(
          balance,
          escrow,
          ev['blockNumber'],
          timeStamp,
          ev['gasPrice'],
          ev['gasUsed'],
          ev['transactionHash']);
    });

    // Guarantee the results are sorted by time descending.
    list.sort((a: LotteryPotUpdateEvent, b: LotteryPotUpdateEvent) => {
      return b.timeStamp.getTime() - a.timeStamp.getTime();
    });

    return list;
  }

  // Pad a 40 character address to 64 characters
  static pad64Chars(address: Address) {
    if (address.startsWith("0x")) {
      address = address.substring(2);
    }
    _assert(address.length === 40, "invalid length");
    return '0x000000000000000000000000' + address;
  }

  public static txLink(txHash: string) {
    return `https://etherscan.io/tx/${txHash}`;
  }
}

function _assert(condition: boolean, message: string) {
  if (!condition) {
    throw message || "Assertion failed";
  }
}

export class LotteryPotUpdateEvent {
  public balance: BigInt;
  public escrow: BigInt;
  public blockNumber: string;
  public timeStamp: Date;
  public gasPrice: string;
  public gasUsed: string;
  public transactionHash: string;

  constructor(balance: BigInt, escrow: BigInt, blockNumber: string, timeStamp: Date, gasPrice: string, gasUsed: string, transactionHash: string) {
    this.balance = balance;
    this.escrow = escrow;
    this.blockNumber = blockNumber;
    this.timeStamp = timeStamp;
    this.gasPrice = gasPrice;
    this.gasUsed = gasUsed;
    this.transactionHash = transactionHash;
  }
}

