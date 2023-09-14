import 'package:orchid/api/orchid_user_config/orchid_user_param.dart';
import 'package:orchid/api/orchid_eth/eth_rpc.dart';
import 'package:orchid/api/orchid_eth/tokens_legacy.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/util/hex.dart';

import '../abi_encode.dart';
import '../orchid_account.dart';
import '../orchid_lottery.dart';
import '../../orchid_crypto.dart';
import 'orchid_contract_v0.dart';

class OrchidEthereumV0 {
  static OrchidEthereumV0 _shared = OrchidEthereumV0._init();
  static int startBlock = 872000;

  static String get _rpc {
    if (OrchidUserParams().test) {
      return Chains.GanacheTest.providerUrl;
    }
    return Chains.Ethereum.providerUrl;
  }

  OrchidEthereumV0._init();

  factory OrchidEthereumV0() {
    return _shared;
  }

  /*
    function look(address funder, address signer) external view returns (uint128, uint128, uint256, OrchidVerifier, bytes32, bytes memory) {
      Pot storage pot = lotteries_[funder].pots_[signer];
      return (pot.amount_, pot.escrow_, pot.unlock_, pot.verify_, pot.codehash_, pot.shared_);
    }

    Example:
    curl https://cloudflare-eth.com -H 'Content-Type: application/json' --data
      '{"jsonrpc":"2.0",
        "method":'eth_call',
        "params":[{
           "to": "0x38cf68E1d19a0b2d2Ba73865E4c85aA1A544C1BF",
           "data": "0x1554ad5d000000000000000000000000405bc10e04e3f487e9925ad5815e4406d78b769e00000000000000000000000040797C3fa232ff87d59e2c3241448C5AC8537D07"},
           'latest'],
        "id":1}'
    Result:
    {"jsonrpc":"2.0","id":1,"result":"0x000000000000000000000000000000000000000000000002b5e3af16b18800000000000000000000000000000000000000000000000000008ac7230489e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000"}
  */
  static Future<LotteryPot> getLotteryPot(
      EthereumAddress funder, EthereumAddress signer) async {
    logDetail("fetch pot V0 for: $funder, $signer, url = $_rpc");

    // construct the abi encoded eth_call
    var params = [
      {
        "to": "${OrchidContractV0.lotteryContractAddressV0String}",
        "data": "0x${OrchidContractV0.lotteryLookMethodHash}"
            "${AbiEncode.address(funder)}"
            "${AbiEncode.address(signer)}"
      },
      'latest'
    ];

    String result = await _jsonRpc(method: 'eth_call', params: params);
    if (!result.startsWith('0x')) {
      log("Error result: $result");
      throw Exception();
    }

    // Parse the results
    var buff = HexStringBuffer(result);
    OXT balance = OXT.fromInt(buff.takeUint128()); // uint128 padded
    OXT deposit = OXT.fromInt(buff.takeUint128()); // uint128 padded
    BigInt unlock = buff.takeUint256(); // uint256
    // For v0 the warned amount is all or nothing.
    OXT warned = unlock == BigInt.zero ? OXT.zero : deposit;

    return LotteryPot(
        balance: balance, deposit: deposit, unlock: unlock, warned: warned);
  }

  /// Get Orchid transactions associated with Update events that affect the balance.
  /// Transactions are returned in date order.
  Future<List<OrchidUpdateTransactionV0>> getUpdateTransactions({
    required EthereumAddress funder,
    required EthereumAddress signer,
  }) async {
    List<OrchidUpdateEventV0> events = await getUpdateEvents(funder, signer);
    List<OrchidUpdateTransactionV0> transactions =
        await Future.wait(events.map((event) async {
      var tx = await getTransactionResult(event.transactionHash);
      return OrchidUpdateTransactionV0(tx, event);
    }));
    return transactions;
  }

  /*
    curl \
      $url -H 'Content-Type: application/json' \
      --data '{"jsonrpc":"2.0","method":"eth_getTransactionByHash","params": ["'$txHash'"], "id":1}'
   */
  Future<OrchidTransactionV0> getTransactionResult(
      String transactionHash) async {
    var params = [transactionHash];
    return OrchidTransactionV0.fromJsonRpcResult(
        await _jsonRpc(method: 'eth_getTransactionByHash', params: params));
  }

  /*
  curl \
    $url -H 'Content-Type: application/json' \
    --data '{"jsonrpc":"2.0","method":"eth_getLogs",
      "params": [{ "topics": ["'$updateEventHash'", "'$funder'", "'$signer'"], "fromBlock": "'$startBlock'" }], "id":1}'

  {
    "id": 1,
    "jsonrpc": "2.0",
    "result": [
      {
        # oxt lottery contract
        "address": "0xb02396f06cc894834b7934ecf8c8e5ab5c1d12f1",
        "topics": [
          # hash of the update event
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
    ]
  }
   */
  Future<List<OrchidUpdateEventV0>> getUpdateEvents(
    EthereumAddress funder,
    EthereumAddress signer,
  ) async {
    // log("fetch update events for: $funder, $signer, url = $_rpc");
    var params = [
      {
        "topics": [
          OrchidContractV0.updateEventHashV0,
          AbiEncode.address(funder, prefix: true),
          AbiEncode.address(signer, prefix: true)
        ],
        "fromBlock": '0x' + startBlock.toRadixString(16)
      }
    ];
    dynamic results = await _jsonRpc(method: 'eth_getLogs', params: params);
    List<OrchidUpdateEventV0> events =
        results.map<OrchidUpdateEventV0>((var result) {
      return OrchidUpdateEventV0.fromJsonRpcResult(result);
    }).toList();
    return events;
  }

  Future<List<OrchidCreateEventV0>> getCreateEvents(
    EthereumAddress signer,
  ) async {
    log("fetch create events for: $signer, url = $_rpc");
    var params = [
      {
        "topics": [
          OrchidContractV0.createEventHashV0,
          "null", // no funder topic for index 1
          AbiEncode.address(signer, prefix: true)
        ],
        "fromBlock": '0x' + startBlock.toRadixString(16)
      }
    ];
    dynamic results = await _jsonRpc(method: 'eth_getLogs', params: params);
    List<OrchidCreateEventV0> events =
        results.map<OrchidCreateEventV0>((var result) {
      return OrchidCreateEventV0.fromJsonRpcResult(result);
    }).toList();
    return events;
  }

  Future<List<Account>> discoverAccounts(
      {required StoredEthereumKey signer}) async {
    // Discover accounts for the active identity on V0 Ethereum.
    List<OrchidCreateEventV0> v0CreateEvents =
        await OrchidEthereumV0().getCreateEvents(signer.address);
    return v0CreateEvents.map((event) {
      return Account.fromSignerKeyRef(
          signerKey: signer.ref(),
          chainId: Chains.ETH_CHAINID,
          funder: event.funder);
    }).toList();
  }

  static Future<dynamic> _jsonRpc({
    required String method,
    List<Object> params = const [],
  }) async {
    return EthereumJsonRpc.ethJsonRpcCall(
        url: _rpc, method: method, params: params);
  }
}
