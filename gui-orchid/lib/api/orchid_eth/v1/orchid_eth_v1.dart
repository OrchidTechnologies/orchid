import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/util/hex.dart';

import '../../configuration/orchid_vpn_config/orchid_vpn_config.dart';
import '../orchid_account.dart';
import '../../orchid_budget_api.dart';
import '../../orchid_crypto.dart';
import '../v0/orchid_eth_v0.dart';
import '../v0/orchid_contract_v0.dart';

class OrchidEthereumV1 {
  static OrchidEthereumV1 _shared = OrchidEthereumV1._init();

  // Lottery contract address (all chains).
  // TODO: This is the temporary xDai V1 contract address
  static var lotteryContractAddressV1 =
      '0xDBbB66055F403aD3cb605f2406aC6529525E0000';

  OrchidEthereumV1._init();

  factory OrchidEthereumV1() {
    return _shared;
  }

  DateTime _lastGasPriceTime;
  Token _lastGasPrice;

  Future<Token> getGasPrice(Chain chain) async {
    TokenType tokenType = chain.nativeCurrency;

    // Allow override via config for testing
    var jsConfig = await OrchidVPNConfig.getUserConfigJS();
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

  Future<List<OrchidCreateEvent>> getCreateEvents(
    Chain chain,
    EthereumAddress signer,
  ) async {
    print("fetch update events for: $signer, url = ${chain.providerUrl}");
    const createEventHash =
        "0x96b5b9b8a7193304150caccf9b80d150675fa3d6af57761d8d8ef1d6f9a1a909";
    var startBlock = 0; // TODO: per chain
    var params = [
      {
        "topics": [
          createEventHash,
          "null", // no funder topic for index 1
          abiEncoded(signer, prefix: true)
        ],
        "fromBlock": "0x" + startBlock.toRadixString(16)
      }
    ];
    dynamic results = await jsonRPC(
        url: chain.providerUrl, method: "eth_getLogs", params: params);
    List<OrchidCreateEvent> events =
        results.map<OrchidCreateEvent>((var result) {
      return OrchidCreateEventV0.fromJsonRpcResult(result);
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

    var readMethodHash = '5185c7d7';

    // construct the abi encoded eth_call
    var params = [
      {
        "to": "$lotteryContractAddressV1",
        "data":
            "0x$readMethodHash${abiEncoded(funder)}${abiEncoded(signer)}${abiEncoded(EthereumAddress.zero)}"
      },
      "latest"
    ];

    String result = await jsonRPC(
        url: chain.providerUrl, method: "eth_call", params: params);
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

    return LotteryPot(
        balance: balance, deposit: deposit, unlock: unlock);
  }

  static String abiEncoded(EthereumAddress address, {prefix: false}) {
    return OrchidEthereumV0.abiEncoded(address, prefix: prefix);
  }

  static Future<dynamic> jsonRPC({
    @required String url,
    @required String method,
    List<Object> params = const [],
  }) async {
    return OrchidEthereumV0.jsonRPCForUrl(
        url: url, method: method, params: params);
  }
}
