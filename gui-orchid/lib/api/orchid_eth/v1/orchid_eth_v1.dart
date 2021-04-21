import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/util/hex.dart';
import 'package:orchid/util/units.dart';

import '../abi_encode.dart';
import '../orchid_account.dart';
import '../../orchid_budget_api.dart';
import '../../orchid_crypto.dart';
import '../v0/orchid_eth_v0.dart';
import '../v0/orchid_contract_v0.dart';
import 'orchid_contract_v1.dart';

class OrchidEthereumV1 {
  static OrchidEthereumV1 _shared = OrchidEthereumV1._init();

  OrchidEthereumV1._init();

  factory OrchidEthereumV1() {
    return _shared;
  }

  DateTime _lastGasPriceTime;
  Token _lastGasPrice;

  Future<Token> getGasPrice(Chain chain) async {
    TokenType tokenType = chain.nativeCurrency;

    // Allow override via config for testing
    var jsConfig = await OrchidUserConfig().getUserConfigJS();
    double overrideValue = jsConfig.evalDoubleDefault('gasPrice', null);
    if (overrideValue != null) {
      return tokenType.fromDouble(overrideValue);
    }

    // Cache for a period of time
    if (_lastGasPrice != null &&
        DateTime.now().difference(_lastGasPriceTime) < Duration(minutes: 5)) {
      print("returning cached gas price");
      return _lastGasPrice;
    }

    print("fetching gas price");
    String result =
        await jsonRPC(url: chain.providerUrl, method: "eth_gasPrice");
    if (result.startsWith('0x')) {
      result = result.substring(2);
    }
    _lastGasPrice = tokenType.fromInt(BigInt.parse(result, radix: 16));
    _lastGasPriceTime = DateTime.now();
    return _lastGasPrice;
  }

  /*
    event Create(IERC20 indexed token, address indexed funder, address indexed signer);
    event Update(bytes32 indexed key, uint256 escrow_amount);
    event Delete(bytes32 indexed key, uint256 unlock_warned);
   */
  Future<List<OrchidCreateEvent>> getCreateEvents(
    Chain chain,
    EthereumAddress signer,
  ) async {
    print("fetch update events for: $signer, url = ${chain.providerUrl}");
    var startBlock = 0; // per chain
    var params = [
      {
        "address": "${await OrchidContractV1.lotteryContractAddressV1}",
        "topics": [
          OrchidContractV1.createEventHashV1, // topic[0]
          "null", // no token address specified for topic[1]
          "null", // no funder address specified for topic[2]
          AbiEncode.address(signer, prefix: true) // topic[3]
        ],
        "fromBlock": "0x" + startBlock.toRadixString(16)
      }
    ];
    dynamic results = await jsonRPC(
        url: chain.providerUrl, method: "eth_getLogs", params: params);
    List<OrchidCreateEvent> events =
        results.map<OrchidCreateEvent>((var result) {
      return OrchidCreateEventV1.fromJsonRpcResult(result);
    }).toList();
    return events;
  }

  Future<List<Account>> discoverAccounts(
      {chain: Chain, signer: StoredEthereumKey}) async {
    List<OrchidCreateEvent> createEvents =
        await getCreateEvents(chain, signer.address);
    return createEvents.map((event) {
      return Account(
          version: 1,
          identityUid: signer.uid,
          chainId: chain.chainId,
          funder: event.funder);
    }).toList();
  }

  static Future<LotteryPot> getLotteryPot(
      {chain: Chain, funder: EthereumAddress, signer: EthereumAddress}) async {
    print("fetch pot for: $funder, $signer, chain = $chain");

    var address = AbiEncode.address;
    // construct the abi encoded eth_call
    var params = [
      {
        "to": "${await OrchidContractV1.lotteryContractAddressV1}",
        "data":
            "0x${OrchidContractV1.readMethodHash}"
                "${address(EthereumAddress.zero)}"
                "${address(funder)}"
                "${address(signer)}"
      },
      "latest"
    ];

    String result = await ethCall(url: chain.providerUrl, params: params);
    if (!result.startsWith("0x")) {
      print("Error result: $result");
      throw Exception();
    }

    // Parse the results:
    //   returns (uint256, uint256, uint256) escrow_amount, warned, bound

    var buff = HexStringBuffer(result);
    BigInt escrowAmount = buff.takeUint256();
    TokenType tokenType = chain.nativeCurrency;

    Token deposit = tokenType.fromInt(escrowAmount >> 128);
    BigInt maskLow128 = (BigInt.from(1) << 128) - BigInt.from(1);
    Token balance = tokenType.fromInt(escrowAmount & maskLow128);
    BigInt unlock = buff.takeUint256();
    //EthereumAddress verifier = EthereumAddress(buff.takeAddress());

    return LotteryPot(balance: balance, deposit: deposit, unlock: unlock);
  }

  /// Get the Chainlink bandwidth price oracle value
  // curl $url -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_call","params":[{"to": "0x8bD3feF1abb94E6587fCC2C5Cb0931099D0893A0", "data": "0x50d25bcd"}, "latest"],"id":1}'
  static Future<USD> getBandwidthPrice() async {
    var contractAddress = '0x8bD3feF1abb94E6587fCC2C5Cb0931099D0893A0';
    var latestAnswerHash = '0x50d25bcd';

    // construct the abi encoded eth_call
    var params = [
      {"to": contractAddress, "data": latestAnswerHash},
      "latest"
    ];

    String result = await ethCall(url: Chains.Ethereum.providerUrl, params: params);
    if (!result.startsWith("0x")) {
      print("Error result: $result");
      throw Exception();
    }

    // Parse the results:
    var buff = HexStringBuffer(result);
    BigInt value = buff.takeUint256();
    return USD(value.toDouble() / 1e5);
  }

  static Future<dynamic> ethCall({
    @required String url,
    List<Object> params = const [],
  }) async {
    return OrchidEthereumV0.ethJsonRpcCall(
        url: url, method: "eth_call", params: params);
  }

  static Future<dynamic> jsonRPC({
    @required String url,
    @required String method,
    List<Object> params = const [],
  }) async {
    return OrchidEthereumV0.ethJsonRpcCall(
        url: url, method: method, params: params);
  }
}
