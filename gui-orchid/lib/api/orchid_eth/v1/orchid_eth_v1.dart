import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/util/hex.dart';
import 'package:orchid/util/units.dart';

import '../../configuration/orchid_vpn_config/orchid_vpn_config.dart';
import '../abi_encode.dart';
import '../eth_transaction.dart';
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
    var startBlock = 0; // TODO: per chain
    var params = [
      {
        "address": "${await OrchidContractV1.lotteryContractAddressV1}",
        "topics": [
          OrchidContractV1.createEventHashV1,
          "null", // no funder topic for index 1
          AbiEncode.address(signer, prefix: true)
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

    var address = AbiEncode.address;
    // construct the abi encoded eth_call
    var params = [
      {
        "to": "${await OrchidContractV1.lotteryContractAddressV1}",
        "data":
            "0x${OrchidContractV1.readMethodHash}${address(funder)}${address(signer)}${address(EthereumAddress.zero)}"
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

    return LotteryPot(balance: balance, deposit: deposit, unlock: unlock);
  }

  /// Create a default funding transaction allocating the total usd value
  /// in USD among balance, deposit, and gas.  This method chooses a
  /// conservative gas price and exchange rate for the native currency.
  Future<EthereumTransaction> createFundingTransaction({
    Chain chain,
    EthereumAddress signer,
    USD totalUsdValue,
  }) async {
    var currency = chain.nativeCurrency;

    // Gas
    var gasPriceMultiplier = 1.1;
    var gasPrice =
        (await getGasPrice(chain)).multiplyDouble(gasPriceMultiplier);
    var gas = OrchidContractV1.lotteryMoveMaxGas;
    var gasCost = gasPrice.multiplyInt(gas);

    // Allocate value
    var usdToTokenRate = await OrchidPricing().usdToTokenRate(currency);
    var totalTokenValue =
        currency.fromDouble(totalUsdValue.value * usdToTokenRate);
    var useableTokenValue = totalTokenValue.subtract(gasCost);

    var contract =
        EthereumAddress.from(await OrchidContractV1.lotteryContractAddressV1);

    // TODO: We currently have no way of knowing if the account exists.
    // TODO: As a placeholder we will just always allocate a fraction to escrow.
    var escrowPercentage = 0.1;
    var escrow = useableTokenValue * escrowPercentage;

    var moveCall =
        OrchidContractV1.abiEncodeMove(signer, escrow.intValue, BigInt.zero);

    log("eth: createFundingTransaction "
        "totalUsdValue = $totalUsdValue, "
        "totalTokenValue = $totalTokenValue, "
        "useableTokenValue = $useableTokenValue, "
        "escrow = $escrow");
    return EthereumTransaction(
      from: signer,
      to: contract,
      gas: gas,
      gasPrice: gasPrice.intValue,
      value: useableTokenValue.intValue,
      chainId: chain.chainId,
      data: moveCall,
    );
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
