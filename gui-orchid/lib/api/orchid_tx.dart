import 'package:orchid/util/hex.dart';
import 'package:orchid/util/units.dart';

enum OrchidTransactionType {
  unknown,
  push,
  pull,
  grab,
  bind,
  move,
  warn,
  yank,
  kill,
  burn,
  give,
  lock,
}

class OrchidUpdateTransaction {
  OrchidTransaction tx;
  OrchidUpdateEvent update;

  OrchidUpdateTransaction(this.tx, this.update);

  @override
  String toString() {
    return 'OrchidUpdateTransaction{tx: $tx, update: $update}';
  }
}

class OrchidTransaction {

  static var lotteryV0Methods = {
    OrchidTransactionType.push: 0x73fb4644,
    OrchidTransactionType.pull: 0xa6cbd6e3,
    OrchidTransactionType.grab: 0x66458bbd,
    OrchidTransactionType.bind: 0xf8825a0c,
    OrchidTransactionType.move: 0x043d695f,
    OrchidTransactionType.warn: 0xe53b3f6d,
    OrchidTransactionType.yank: 0x5f51b34e,
    OrchidTransactionType.kill: 0x0, // todo:
    OrchidTransactionType.burn: 0x0, // todo:
    OrchidTransactionType.give: 0x0, // todo:
    OrchidTransactionType.lock: 0x0, // todo:
  };

  String transactionHash;
  OrchidTransactionType type;

  // Payment amount or null for no payment
  OXT payment;

  bool get isPayment {
    return payment != null;
  }

  OrchidTransaction({this.transactionHash, this.type, this.payment});

  /*
  {
    "jsonrpc": "2.0",
    "id": 1,
    "result": {
      "hash": "0x0ebc4a5f87b02e595146e6a0760a5ad35560d81a48bb7a47e00e149dc7a93a63",
      "blockHash": "0xf02552c4030b704d131545dc324c02703bc6054a4117759c9ba562840fec3ae0",
      "blockNumber": "0xaa4c31",
      "from": "0xbf916027d46ce5f14790c2242dbab15b15f79f63",
      "gas": "0x14820",
      "gasPrice": "0x430e23400",
      "input": "0x66458bbdf843d92934e7bea707ceb8ab6f17d07b300a949b477b9007e05cd7a3b77a8aff7be9533c72823a29c2d91d4470bae08d94931b5e55b50dc8a1c8e2adbfbb5f4b000000000000000000000000000000000000000000000000000000005f9c885ffb9309d24f9603e52240733322cd7ed315d619106cca3cd445fda60d51ed53ef000000000000000000000000000000000000000000000000000000000000001c5e52cb92631112a291b09de9bb1ccfec557a2558a62e0f01abf1d2cdbb28e66e06558c438b215f89c080c4f40929176dd4a57cab4bbec5eb6385f5839cc50ef20000000000000000000000000000000000000000000000065ea3db7554660000000000000000000000000000000000000000a3762f87d255d9db4155dca36155000000000000000000000000000000000000000000000000000000005f9ca47f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000027fb8edcf854602704fe8438243d0959219db1260000000000000000000000006941dcbfe22d8806e89c1e353c9218b6ee083ed800000000000000000000000000000000000000000000000000000000000001e0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
      "nonce": "0xe",
      "r": "0xaf3324fd01938710048e8f516d5d122a4729db7a7d0a54b48fb1d5b5ccb1d6df",
      "s": "0x361ac526319b3a8b8d8ffb93b8361287f9374bac7c031eb4f9a72e0d935804cb",
      "to": "0xb02396f06cc894834b7934ecf8c8e5ab5c1d12f1",
      "transactionIndex": "0x49",
      "v": "0x26",
      "value": "0x0"
    }
  }

  Function: grab(
    bytes32 reveal, bytes32 commit, uint256 issued, bytes32 nonce, uint8 v, bytes32 r, bytes32 s,
    uint128 amount, uint128 ratio, uint256 start, uint128 range, address funder, address recipient,
    bytes receipt, bytes32[] old)
  MethodID: 0x66458bbd
  [0]:  f843d92934e7bea707ceb8ab6f17d07b300a949b477b9007e05cd7a3b77a8aff
  [1]:  7be9533c72823a29c2d91d4470bae08d94931b5e55b50dc8a1c8e2adbfbb5f4b
  [2]:  000000000000000000000000000000000000000000000000000000005f9c885f
   */
  static OrchidTransaction fromJsonRpcResult(dynamic result) {
    // Parse the results
    var hash = result['hash'];
    var buff = HexStringBuffer(result['input']);
    int methodId = buff.takeMethodId();
    var inverseMap = lotteryV0Methods.map((k, v) => MapEntry(v, k));
    OrchidTransactionType transactionType =
        inverseMap[methodId] ?? OrchidTransactionType.unknown;

    OXT amount;
    if (transactionType == OrchidTransactionType.grab) {
      buff.takeBytes32(); // bytes32 reveal,
      buff.takeBytes32(); // bytes32 commit,
      buff.takeUint256(); // uint256 issued,
      buff.takeBytes32(); // bytes32 nonce,
      buff.takeUint8();   // uint8 v,
      buff.takeBytes32(); // bytes32 r,
      buff.takeBytes32(); // bytes32 s
      amount = OXT.fromKeiki(buff.takeUint128());
    }

    return OrchidTransaction(
        transactionHash: hash, type: transactionType, payment: amount ?? null);
  }

  @override
  String toString() {
    return 'OrchidUpdateTransaction{transactionHash: $transactionHash, type: $type, payment: $payment}';
  }
}

class OrchidUpdateEvent {
  String transactionHash;
  OXT endBalance;
  OXT endDeposit;

  OrchidUpdateEvent({this.transactionHash, this.endBalance, this.endDeposit});

  /*
    {
      "address": "0xb02396f06cc894834b7934ecf8c8e5ab5c1d12f1",
      "topics": [
        "0x3cd5941d0d99319105eba5f5393ed93c883f132d251e56819e516005c5e20dbc",
        "0x00000000000000000000000053244d810bd540c02b36d8b56215de976010c523",
        "0x0000000000000000000000008452087e2c73a6a9fe1033e728ce9f2c72556b0e"
      ],
      "data": "0x00000000000000000000000000000000000000000000000107ad8f556c6c0000000000000000000000000000000000000000000000000001236efcbcbb3400000000000000000000000000000000000000000000000000000000000000000000",
      "blockNumber": "0xaae229",
      "transactionHash": "0x23b49b83020115c5ec71221d76f15c1795b6a3b06ba594520d803093f1042e1e",
      "transactionIndex": "0x34",
      "blockHash": "0x7d4ff665e76b29607339cf08700cae2380d0afaf7e5deb8a1d0981ddc200a0f2",
      "logIndex": "0x55",
      "removed": false
    }
   */
  static OrchidUpdateEvent fromJsonRpcResult(dynamic result) {
    // Parse the results
    String transactionHash = result['transactionHash'];
    var buff = HexStringBuffer(result['data']);
    OXT balance = OXT.fromKeiki(buff.take(64)); // uint128 padded
    OXT deposit = OXT.fromKeiki(buff.take(64)); // uint128 padded

    return OrchidUpdateEvent(
        transactionHash: transactionHash,
        endBalance: balance,
        endDeposit: deposit);
  }

  @override
  String toString() {
    return 'OrchidUpdateEvent{transactionHash: $transactionHash, endBalance: $endBalance, endDeposit: $endDeposit}';
  }
}
