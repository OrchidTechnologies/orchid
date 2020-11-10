import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:orchid/api/configuration/orchid_vpn_config.dart';
import 'package:orchid/util/hex.dart';
import 'package:orchid/util/units.dart';

import 'orchid_budget_api.dart';
import 'orchid_crypto.dart';
import 'orchid_tx.dart';

class OrchidEthereum {
  static OrchidEthereum _shared = OrchidEthereum._init();
  static int startBlock = 872000;

  static var providerUrl = 'htt' +
      'ps://et' +
      'h-main' +
      'ne' +
      't.alc' +
      'hemya' +
      'pi.i' +
      'o/v' +
      '2/VwJMm1VlCgpmjULmKeaVAt3Ik4XVwxO0';

  // Lottery contract address on main net
  static var lotteryContractAddress =
      '0xb02396f06CC894834b7934ecF8c8E5Ab5C1d12F1';

  // The ABI identifier for the `look` method.
  // Note: The first four bytes of the signature hash (Remix can provide this).
  static var lotteryLookMethodHash = '1554ad5d';

  OrchidEthereum._init();

  factory OrchidEthereum() {
    return _shared;
  }

  // Get the provider URL allowing override in the advanced config
  static Future<String> get url async {
    var jsConfig = await OrchidVPNConfig.getUserConfigJS();
    // Note: This var is also used by the tunnel for the eth provider.
    return jsConfig.evalStringDefault('rpc', providerUrl);
  }

  /*
    function look(address funder, address signer) external view returns (uint128, uint128, uint256, OrchidVerifier, bytes32, bytes memory) {
      Pot storage pot = lotteries_[funder].pots_[signer];
      return (pot.amount_, pot.escrow_, pot.unlock_, pot.verify_, pot.codehash_, pot.shared_);
    }

    Example:
    curl https://cloudflare-eth.com -H 'Content-Type: application/json' --data
      '{"jsonrpc":"2.0",
        "method":"eth_call",
        "params":[{
           "to": "0x38cf68E1d19a0b2d2Ba73865E4c85aA1A544C1BF",
           "data": "0x1554ad5d000000000000000000000000405bc10e04e3f487e9925ad5815e4406d78b769e00000000000000000000000040797C3fa232ff87d59e2c3241448C5AC8537D07"},
           "latest"],
        "id":1}'
    Result:
    {"jsonrpc":"2.0","id":1,"result":"0x000000000000000000000000000000000000000000000002b5e3af16b18800000000000000000000000000000000000000000000000000008ac7230489e800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a00000000000000000000000000000000000000000000000000000000000000000"}
  */
  static Future<LotteryPot> getLotteryPot(
      EthereumAddress funder, EthereumAddress signer) async {
    print("fetch pot for: $funder, $signer, url = ${await url}");

    // construct the abi encoded eth_call
    var params = [
      {
        "to": "$lotteryContractAddress",
        "data":
            "0x$lotteryLookMethodHash${abiEncoded(funder)}${abiEncoded(signer)}"
      },
      "latest"
    ];

    String result = await jsonRPC(method: "eth_call", params: params);
    if (!result.startsWith("0x")) {
      print("Error result: $result");
      throw Exception();
    }

    // Parse the results
    var buff = HexStringBuffer(result);
    OXT balance = OXT.fromKeiki(buff.take(64)); // uint128 padded
    OXT deposit = OXT.fromKeiki(buff.take(64)); // uint128 padded
    BigInt unlock = buff.take(64); // uint256

    // The verifier only has a non-zero value for PACs.
    EthereumAddress verifier;
    try {
      verifier = EthereumAddress(buff.take(64));
    } catch (err) {}

    return LotteryPot(
        balance: balance, deposit: deposit, unlock: unlock, verifier: verifier);
  }

  DateTime _lastGasPriceTime;
  GWEI _lastGasPrice;

  /// Get the current median gas price.
  /// curl $url --data '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":0}'
  /// {"jsonrpc":"2.0","id":0,"result":"0x2cb417800"}
  /// This method is cached for a period of time and safe to call repeatedly.
  Future<GWEI> getGasPrice() async {
    // Allow override via config for testing
    var jsConfig = await OrchidVPNConfig.getUserConfigJS();
    double overrideValue = jsConfig.evalDoubleDefault('gasPrice', null);
    if (overrideValue != null) {
      return GWEI(overrideValue);
    }

    // Cache for a period of time
    if (_lastGasPrice != null &&
        DateTime.now().difference(_lastGasPriceTime) < Duration(minutes: 5)) {
      print("returning cached gas price");
      return _lastGasPrice;
    }

    print("fetching gas price");
    String result = await jsonRPC(method: "eth_gasPrice");
    if (result.startsWith('0x')) {
      result = result.substring(2);
    }
    _lastGasPrice = GWEI.fromWei(BigInt.parse(result, radix: 16));
    _lastGasPriceTime = DateTime.now();
    return _lastGasPrice;
  }

  /// Get Orchid transactions associated with Update events that affect the balance.
  /// Transactions are returned in date order.
  Future<List<OrchidUpdateTransaction>> getUpdateTransactions({
    EthereumAddress funder,
    EthereumAddress signer,
  }) async {
    List<OrchidUpdateEvent> events = await getUpdateEvents(funder, signer);
    List<OrchidUpdateTransaction> transactions =
        await Future.wait(events.map((event) async {
      var tx = await getTransactionResult(event.transactionHash);
      return OrchidUpdateTransaction(tx, event);
    }));
    return transactions;
  }

  /*
    curl \
      $url -H 'Content-Type: application/json' \
      --data '{"jsonrpc":"2.0","method":"eth_getTransactionByHash","params": ["'$txHash'"], "id":1}'
   */
  Future<OrchidTransaction> getTransactionResult(String transactionHash) async {
    //print("fetch transaction for: $transactionHash");
    var params = [transactionHash];
    return OrchidTransaction.fromJsonRpcResult(
        await jsonRPC(method: "eth_getTransactionByHash", params: params));
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
  Future<List<OrchidUpdateEvent>> getUpdateEvents(
    EthereumAddress funder,
    EthereumAddress signer,
  ) async {
    print("fetch update events for: $funder, $signer, url = ${await url}");
    const updateEventHash =
        "0x3cd5941d0d99319105eba5f5393ed93c883f132d251e56819e516005c5e20dbc";
    var params = [
      {
        "topics": [
          updateEventHash,
          abiEncoded(funder, prefix: true),
          abiEncoded(signer, prefix: true)
        ],
        "fromBlock": "0x"+startBlock.toRadixString(16)
      }
    ];
    dynamic results = await jsonRPC(method: "eth_getLogs", params: params);
    List<OrchidUpdateEvent> events = results.map<OrchidUpdateEvent>((var result) {
      return OrchidUpdateEvent.fromJsonRpcResult(result);
    }).toList();
    return events;
  }

  static Future<dynamic> jsonRPC({
    String method,
    List<Object> params = const [],
  }) async {
    // construct the abi encoded eth_call
    var postBody = jsonEncode(
        {"jsonrpc": "2.0", "method": method, "id": 1, "params": params});

    // do the post
    var response = await http.post(await url,
        headers: {"Content-Type": "application/json"}, body: postBody);

    if (response.statusCode != 200) {
      throw Exception("Error status code: ${response.statusCode}");
    }
    var body = json.decode(response.body);
    if (body['error'] != null) {
      throw Exception("fetch error in response: $body");
    }

    return body['result'];
  }

  // Pad a 40 character address to 64 characters with no prefix
  static String abiEncoded(EthereumAddress address, {prefix: false}) {
    return (prefix ? "0x" : "") +
        '000000000000000000000000' +
        address.toString(prefix: false);
  }

  static String quote(String s) {
    return '"' + s + '"';
  }

}
