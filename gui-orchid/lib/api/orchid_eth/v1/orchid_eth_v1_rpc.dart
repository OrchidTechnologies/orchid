import 'dart:math';
import 'package:orchid/api/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_eth/eth_rpc.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/uniswap_v3_contract.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/util/cacheable.dart';
import 'package:orchid/util/hex.dart';

import '../abi_encode.dart';
import '../chains.dart';
import '../orchid_account.dart';
import '../orchid_lottery.dart';
import '../../orchid_crypto.dart';
import '../v0/orchid_contract_v0.dart';
import 'orchid_contract_v1.dart';
import 'orchid_eth_v1.dart';

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
    var jsConfig = OrchidUserConfig().getUserConfig();
    // TODO: gas price override should be per-chain
    double? overrideValue = jsConfig.evalDoubleDefaultNull('gasPrice');
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
    result = Hex.remove0x(result);
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
    logDetail("fetch create events for: $signer, url = ${chain.providerUrl}");
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
      {required Chain chain, required StoredEthereumKey signer}) async {
    List<OrchidCreateEvent> createEvents =
        await _getCreateEvents(chain, signer.address);
    return createEvents.map((event) {
      return Account.fromSignerKeyRef(
          version: 1,
          signerKey: signer.ref(),
          chainId: chain.chainId,
          funder: event.funder);
    }).toList();
  }

  // Note: this method's results are cached by the Account API
  Future<LotteryPot> getLotteryPot(
      {required Chain chain, required EthereumAddress funder, required EthereumAddress signer}) async {
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

  /// Get a uniswap price from the specified pool
  Future<double> getUniswapPrice(
      Chain chain, String poolAddress, int token0Decimals, int token1Decimals) async {
    // log("getUniswapPrice via rpc");
    // construct the abi encoded eth_call
    var params = [
      {"to": "$poolAddress", "data": "0x${UniswapV3Contract.slot0Hash}"},
      "latest"
    ];

    String result = await EthereumJsonRpc.ethCall(
        url: chain.providerUrl, params: params);
    var buff = HexStringBuffer(result);
    // Q64.96 fixed-point number
    BigInt sqrtPriceX96 = buff.takeUint160();
    return pow(sqrtPriceX96.toDouble(), 2) *
        pow(10, token0Decimals) /
        pow(10, token1Decimals) /
        // We need to divide by 2^192 (96 * 2 bits) but without overflowing the divisor
        pow(2, 48) /
        pow(2, 48) /
        pow(2, 48) /
        pow(2, 48);
  }

  static Future<dynamic> _jsonRPC({
    required String url,
    required String method,
    List<Object> params = const [],
  }) async {
    return EthereumJsonRpc.ethJsonRpcCall(
        url: url, method: method, params: params);
  }
}
