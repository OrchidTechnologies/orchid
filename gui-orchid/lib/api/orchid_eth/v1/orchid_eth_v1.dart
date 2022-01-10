import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_eth/eth_rpc.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/util/cacheable.dart';
import 'package:orchid/util/hex.dart';
import 'package:orchid/util/units.dart';

import '../abi_encode.dart';
import '../chains.dart';
import '../orchid_account.dart';
import '../../orchid_budget_api.dart';
import '../../orchid_crypto.dart';
import '../v0/orchid_contract_v0.dart';
import 'orchid_contract_v1.dart';

/// This API describes the read-only eth calls shared by the dapp and the app
/// and allows them to be overridden in the web3 context.
abstract class OrchidEthereumV1 {
  static OrchidEthereumV1 _shared;

  // This method is used by the dapp to set a web3 provider implementation
  static setWeb3Provider(OrchidEthereumV1 impl) {
    _shared = impl;
  }

  /// Return the default eth api provider.  This will be the direct
  /// json rpc endpoint for the chain unless overridden by providing a web3
  /// context provider.
  factory OrchidEthereumV1() {
    if (_shared == null) {
      _shared = OrchidEthereumV1JsonRpcImpl.init();
    }
    return _shared;
  }

  // This gas price call is used for V0 and V1.
  Future<Token> getGasPrice(Chain chain, {bool refresh = false});

  Future<List<Account>> discoverAccounts(
      {Chain chain, StoredEthereumKey signer});

  Future<LotteryPot> getLotteryPot(
      {Chain chain, EthereumAddress funder, EthereumAddress signer});
}

/// Implementation that uses the chain's default json rpc endpoint
class OrchidEthereumV1JsonRpcImpl implements OrchidEthereumV1 {
  OrchidEthereumV1JsonRpcImpl.init();

  // TODO: gas price caching should probably be consolidated at the Chain level.
  Cache<Chain, Token> _gasPriceCache =
      Cache(duration: Duration(seconds: 15), name: 'gas price');

  // TODO: gas price should probably be consolidated at the Chain level.
  // TODO: and shared with the web3 impl.
  /// Get gas price cached
  Future<Token> getGasPrice(Chain chain, {bool refresh = false}) async {
    // Allow override via config for testing
    var jsConfig = OrchidUserConfig().getUserConfigJS();
    // TODO: gas price override should be per-chain
    double overrideValue = jsConfig.evalDoubleDefault('gasPrice', null);
    if (overrideValue != null) {
      TokenType tokenType = chain.nativeCurrency;
      return tokenType.fromDouble(overrideValue);
    }

    return _gasPriceCache.get(
        key: chain, producer: _fetchGasPrice, refresh: refresh);
  }

  Future<Token> _fetchGasPrice(Chain chain) async {
    logDetail("Fetching gas price for chain: $chain");
    String result =
        await _jsonRPC(url: chain.providerUrl, method: "eth_gasPrice");
    if (result.startsWith('0x')) {
      result = result.substring(2);
    }

    TokenType tokenType = chain.nativeCurrency;
    return tokenType.fromInt(BigInt.parse(result, radix: 16));
  }

  // TODO: We should persistently cache these by block number
  /*
    event Create(IERC20 indexed token, address indexed funder, address indexed signer);
    event Update(bytes32 indexed key, uint256 escrow_amount);
    event Delete(bytes32 indexed key, uint256 unlock_warned);
   */
  Future<List<OrchidCreateEvent>> _getCreateEvents(
    Chain chain,
    EthereumAddress signer,
  ) async {
    log("fetch create events for: $signer, url = ${chain.providerUrl}");
    var startBlock = 0; // per chain
    var params = [
      {
        "address": "${OrchidContractV1.lotteryContractAddressV1}",
        "topics": [
          OrchidContractV1.createEventHashV1, // topic[0]
          [], // no token address specified for topic[1]
          [], // no funder address specified for topic[2]
          AbiEncode.address(signer, prefix: true) // topic[3]
        ],
        "fromBlock": "0x" + startBlock.toRadixString(16)
      }
    ];
    dynamic results = await _jsonRPC(
        url: chain.providerUrl, method: "eth_getLogs", params: params);
    List<OrchidCreateEvent> events =
        results.map<OrchidCreateEvent>((var result) {
      return OrchidCreateEventV1.fromJsonRpcResult(result);
    }).toList();
    return events;
  }

  // Note: This method requires signer key because to produce orchid accounts that
  // Note: are capable of signing.  If we need this in the web3 context we should
  // Note: provide another version that accepts the signer address and produces
  // Note: tracked accounts by address.
  Future<List<Account>> discoverAccounts(
      {Chain chain, StoredEthereumKey signer}) async {
    List<OrchidCreateEvent> createEvents =
        await _getCreateEvents(chain, signer.address);
    return createEvents.map((event) {
      return Account.fromSignerKey(
          version: 1,
          signerKey: signer.ref(),
          chainId: chain.chainId,
          funder: event.funder);
    }).toList();
  }

  // Note: this method's results are cached by the Account API
  Future<LotteryPot> getLotteryPot(
      {Chain chain, EthereumAddress funder, EthereumAddress signer}) async {
    logDetail("fetch pot V1 for: $funder, $signer, chain = $chain");

    var address = AbiEncode.address;
    // construct the abi encoded eth_call
    var params = [
      {
        "to": "${OrchidContractV1.lotteryContractAddressV1}",
        "data": "0x${OrchidContractV1.readMethodHash}"
            "${address(EthereumAddress.zero)}"
            "${address(funder)}"
            "${address(signer)}"
      },
      "latest"
    ];

    String result =
        await EthereumJsonRpc.ethCall(url: chain.providerUrl, params: params);
    // log("XXX: lottery pot fetch result = $result");
    return parseLotteryPotRpcResult(result, chain);
  }

  static LotteryPot parseLotteryPotRpcResult(String result, Chain chain) {
    if (!result.startsWith("0x")) {
      log("Error result: $result");
      throw Exception("can't parse lottery pot rpc result: $result");
    }
    // Parse the results:
    // struct Account {
    //         uint256 escrow_amount_;
    //         uint256 unlock_warned_;
    //     }
    var buff = HexStringBuffer(result);
    BigInt escrowAmount = buff.takeUint256();
    BigInt unlockWarned = buff.takeUint256();

    TokenType tokenType = chain.nativeCurrency;
    BigInt maskLow128 = (BigInt.one << 128) - BigInt.one;
    Token escrow = tokenType.fromInt(escrowAmount >> 128);
    Token amount = tokenType.fromInt(escrowAmount & maskLow128);
    BigInt unlock = unlockWarned >> 128;
    Token warned = tokenType.fromInt(unlockWarned & maskLow128);

    return LotteryPot(
        balance: amount, deposit: escrow, unlock: unlock, warned: warned);
  }

  static Future<dynamic> _jsonRPC({
    @required String url,
    @required String method,
    List<Object> params = const [],
  }) async {
    return EthereumJsonRpc.ethJsonRpcCall(
        url: url, method: method, params: params);
  }
}

class OrchidBandwidthPricing {
  static SingleCache<USD> _bandwidthPriceCache =
      SingleCache(duration: Duration(seconds: 60), name: "bandwidth price");

  /// Get the Chainlink bandwidth price oracle value
  static Future<USD> getBandwidthPrice({bool refresh = false}) async {
    return _bandwidthPriceCache.get(
        producer: _fetchBandwidthPrice, refresh: refresh);
  }

  /// Get the Chainlink bandwidth price oracle value
  // curl $url -H 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_call","params":[{"to": "0x8bD3feF1abb94E6587fCC2C5Cb0931099D0893A0", "data": "0x50d25bcd"}, "latest"],"id":1}'
  static Future<USD> _fetchBandwidthPrice() async {
    var contractAddress = '0x8bD3feF1abb94E6587fCC2C5Cb0931099D0893A0';
    var latestAnswerHash = '0x50d25bcd';

    // construct the abi encoded eth_call
    var params = [
      {"to": contractAddress, "data": latestAnswerHash},
      "latest"
    ];

    String result = await EthereumJsonRpc.ethCall(
        url: Chains.Ethereum.providerUrl, params: params);
    if (!result.startsWith("0x")) {
      log("Error result: $result");
      throw Exception();
    }

    // Parse the results:
    var buff = HexStringBuffer(result);
    BigInt value = buff.takeUint256();
    return USD(value.toDouble() / 1e5);
  }
}
