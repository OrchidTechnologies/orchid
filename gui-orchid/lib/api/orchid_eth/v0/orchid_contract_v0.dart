import 'package:orchid/api/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_user_config/orchid_user_param.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/tokens_legacy.dart';
import 'package:orchid/util/hex.dart';

class OrchidContractV0 {
  // The final lottery V0 contract address on Ethereum main net.
  static var _lotteryContractAddressV0 =
      '0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1';
  static var _testLotteryContractAddressV0 =
      '0x785883f0594F0347b1B2aF02257bd6198Eb4104A';

  static var _oxtContractAddress = '0x4575f41308EC1483f3d399aa9a2826d74Da13Deb';
  static var _testOXTContractAddress =
      '0xB4b5e4Ba41d7a0d41d8426C99cCCB090d8D2C3Ba';

  static String get lotteryContractAddressV0String {
    // if (OrchidUserParams().test) {
    //   return _testLotteryContractAddressV0;
    // }
    return OrchidUserConfig()
        .getUserConfig()
        .evalStringDefault("lottery0", _lotteryContractAddressV0);
  }

  static EthereumAddress get lotteryContractAddressV0 {
    return EthereumAddress.from(lotteryContractAddressV0String);
  }

  static String get oxtContractAddressString {
    if (OrchidUserParams().test) {
      return _testOXTContractAddress;
    }
    return OrchidUserConfig()
        .getUserConfig()
        .evalStringDefault("oxt", _oxtContractAddress);
  }

  static EthereumAddress get oxtContractAddress {
    return EthereumAddress.from(oxtContractAddressString);
  }

  static final _testDirectoryContractAddressV0 = '0xxxx';

  // OXT Directory on main net
  static final _directoryContractAddressV0 =
      '0x918101FB64f467414e9a785aF9566ae69C3e22C5';

  static String get directoryContractAddressString {
    if (OrchidUserParams().test) {
      return _testDirectoryContractAddressV0;
    }
    return _directoryContractAddressV0;
  }

  static EthereumAddress get directoryContractAddress {
    return EthereumAddress.from(directoryContractAddressString);
  }

  static String updateEventHashV0 =
      "0x3cd5941d0d99319105eba5f5393ed93c883f132d251e56819e516005c5e20dbc";

  static String createEventHashV0 =
      "0x96b5b9b8a7193304150caccf9b80d150675fa3d6af57761d8d8ef1d6f9a1a909";

  // The ABI identifier for the `look` method.
  static var lotteryLookMethodHash = '1554ad5d';

  static int gasLimitToRedeemTicketV0 = 100000;
  static int gasLimitLotteryPush = 175000;
  static int gasLimitCreateAccount = gasLimitLotteryPush;

  static int gasLimitApprove = 200000;

  static int gasLimitDirectoryPush = 300000;
  static int gasLimitDirectoryPull = 300000;
  static int gasLimitDirectoryTake = 300000;

  static List<String> lotteryAbi = [
    'event Update(address indexed funder, address indexed signer, uint128 amount, uint128 escrow, uint256 unlock)',
    'event Create(address indexed funder, address indexed signer)',
    'event Bound(address indexed funder, address indexed signer)',
    'function look(address funder, address signer) external view returns (uint128, uint128, uint256, address, bytes32, bytes memory)',
    'function push(address signer, uint128 total, uint128 escrow)',
    'function move(address signer, uint128 amount)',
    'function warn(address signer)',
    'function lock(address signer)',
    'function pull(address signer, address payable target, bool autolock, uint128 amount, uint128 escrow)',
    'function yank(address signer, address payable target, bool autolock)',
  ];

  static List<String> directoryAbi = [
    'function heft(address stakee) external view returns (uint256)',
    'function push(address stakee, uint256 amount, uint128 delay)',
    'function pull(address stakee, uint256 amount, uint256 index)',
    'function take(uint256 index, uint256 amount, address payable target)',
    // 'function transfer(address recipient, uint256 amount) external returns (bool)',
    // 'function transferFrom(address sender, address recipient, uint256 amount) external returns (bool)',
    // 'function what() external view returns (IERC20)',
    // 'function name(address staker, address stakee) public pure returns (bytes32)',
    // 'function have() public view returns (uint256)',
    // 'function seek(uint256 point) public view returns (address, uint128)',
    // 'function pick(uint128 percent) external view returns (address, uint128)',
    // 'function wait(address stakee, uint128 delay)',
    // 'function stop(uint256 index, uint256 amount, uint128 delay)',
  ];
}

enum OrchidTransactionTypeV0 {
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

class OrchidUpdateTransactionV0 {
  OrchidTransactionV0 tx;
  OrchidUpdateEventV0 update;

  OrchidUpdateTransactionV0(this.tx, this.update);

  @override
  String toString() {
    return 'OrchidUpdateTransaction{tx: $tx, update: $update}';
  }
}

class OrchidTransactionV0 {
  static var lotteryV0Methods = {
    OrchidTransactionTypeV0.push: 0x73fb4644,
    OrchidTransactionTypeV0.pull: 0xa6cbd6e3,
    OrchidTransactionTypeV0.grab: 0x66458bbd,
    OrchidTransactionTypeV0.bind: 0xf8825a0c,
    OrchidTransactionTypeV0.move: 0x043d695f,
    OrchidTransactionTypeV0.warn: 0xe53b3f6d,
    OrchidTransactionTypeV0.yank: 0x5f51b34e,
    OrchidTransactionTypeV0.kill: 0x0, // todo:
    OrchidTransactionTypeV0.burn: 0x0, // todo:
    OrchidTransactionTypeV0.give: 0x0, // todo:
    OrchidTransactionTypeV0.lock: 0x0, // todo:
  };

  String transactionHash;
  OrchidTransactionTypeV0 type;

  // Payment amount or null for no payment
  OXT? payment;

  bool get isPayment {
    return payment != null;
  }

  OrchidTransactionV0(
      {required this.transactionHash,
      required this.type,
      required this.payment});

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
  static OrchidTransactionV0 fromJsonRpcResult(dynamic result) {
    // Parse the results
    var hash = result['hash'];
    var buff = HexStringBuffer(result['input']);
    int methodId = buff.takeMethodId();
    var inverseMap = lotteryV0Methods.map((k, v) => MapEntry(v, k));
    OrchidTransactionTypeV0 transactionType =
        inverseMap[methodId] ?? OrchidTransactionTypeV0.unknown;

    OXT? amount;
    if (transactionType == OrchidTransactionTypeV0.grab) {
      buff.takeBytes32(); // bytes32 reveal,
      buff.takeBytes32(); // bytes32 commit,
      buff.takeUint256(); // uint256 issued,
      buff.takeBytes32(); // bytes32 nonce,
      buff.takeUint8(); // uint8 v,
      buff.takeBytes32(); // bytes32 r,
      buff.takeBytes32(); // bytes32 s
      amount = OXT.fromInt(buff.takeUint128());
    }

    return OrchidTransactionV0(
        transactionHash: hash, type: transactionType, payment: amount ?? null);
  }

  @override
  String toString() {
    return 'OrchidUpdateTransaction{transactionHash: $transactionHash, type: $type, payment: $payment}';
  }
}

class OrchidUpdateEventV0 {
  String transactionHash;
  OXT endBalance;
  OXT endDeposit;

  OrchidUpdateEventV0(
      {required this.transactionHash,
      required this.endBalance,
      required this.endDeposit});

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
  static OrchidUpdateEventV0 fromJsonRpcResult(dynamic result) {
    // Parse the results
    String transactionHash = result['transactionHash'];
    var buff = HexStringBuffer(result['data']);
    OXT balance = OXT.fromInt(buff.take(64)); // uint128 padded
    OXT deposit = OXT.fromInt(buff.take(64)); // uint128 padded

    return OrchidUpdateEventV0(
        transactionHash: transactionHash,
        endBalance: balance,
        endDeposit: deposit);
  }

  @override
  String toString() {
    return 'OrchidUpdateEvent{transactionHash: $transactionHash, endBalance: $endBalance, endDeposit: $endDeposit}';
  }
}

class OrchidCreateEvent {
  final String transactionHash;
  final EthereumAddress funder;
  final EthereumAddress signer;

  OrchidCreateEvent(
      {required this.transactionHash,
      required this.funder,
      required this.signer});
}

class OrchidCreateEventV1 {
  static OrchidCreateEvent fromJsonRpcResult(dynamic result) {
    // Parse the results
    String transactionHash = result['transactionHash'];
    // topic 0 is the event hash
    // topic 1 is the token address
    var funder =
        EthereumAddress(HexStringBuffer(result['topics'][2]).takeAddress());
    var signer =
        EthereumAddress(HexStringBuffer(result['topics'][3]).takeAddress());

    return OrchidCreateEvent(
        transactionHash: transactionHash, funder: funder, signer: signer);
  }
}

// A create event indicates an initial funding event for a
class OrchidCreateEventV0 implements OrchidCreateEvent {
  final String transactionHash;
  final EthereumAddress funder;
  final EthereumAddress signer;

  OrchidCreateEventV0(
      {required this.transactionHash,
      required this.funder,
      required this.signer});

  static OrchidCreateEventV0 fromJsonRpcResult(dynamic result) {
    // Parse the results
    String transactionHash = result['transactionHash'];
    var funder =
        EthereumAddress(HexStringBuffer(result['topics'][1]).takeAddress());
    var signer =
        EthereumAddress(HexStringBuffer(result['topics'][2]).takeAddress());

    return OrchidCreateEventV0(
        transactionHash: transactionHash, funder: funder, signer: signer);
  }

  @override
  String toString() {
    return 'OrchidCreateEvent{transactionHash: $transactionHash, funder: $funder, signer: $signer}';
  }
}
