// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'token_type.dart';

/*
TODO: embed Chain data from https://chainid.network/chains.json
  https://github.com/ethereum-lists/chains
 */
class Chains {
  static final _defaultEthereumProviderUrl = 'htt' +
      'ps://et' +
      'h-main' +
      'ne' +
      't.alc' +
      'hemya' +
      'pi.i' +
      'o/v' +
      '2/VwJMm1VlCgpmjULmKeaVAt3Ik4XVwxO0';

  static String get defaultEthereumProviderUrl {
    return _overriddenEthereumProviderUrl;
  }

  // Get the provider URL allowing override in the advanced config
  static String get _overriddenEthereumProviderUrl {
    var jsConfig = OrchidUserConfig().getUserConfigJS();
    // Note: This var is also used by the tunnel for the eth provider.
    return jsConfig.evalStringDefault('rpc', _defaultEthereumProviderUrl);
  }

  // Ethereum
  static const int ETH_CHAINID = 1;
  static Chain Ethereum = Chain(
    chainId: ETH_CHAINID,
    name: "Ethereum",
    nativeCurrency: TokenTypes.ETH,
    providerUrl: defaultEthereumProviderUrl,
    // TODO: Missing ETH icon
    icon: SvgPicture.asset('assets/svg/orchid_icon.svg'),
  );

  // xDAI
  static const int XDAI_CHAINID = 100;
  static Chain xDAI = Chain(
    chainId: XDAI_CHAINID,
    name: "xDAI",
    nativeCurrency: TokenTypes.XDAI,
    // providerUrl: 'https://dai.poa.network',
    providerUrl: 'https://rpc.xdaichain.com/',
    icon: SvgPicture.asset('assets/svg/logo-xdai2.svg'),
  );

  // Ganache
  static const int GANACHE_TEST_CHAINID = 1337;
  static Chain GanacheTest = Chain(
    chainId: GANACHE_TEST_CHAINID,
    name: "Ganache Test",
    nativeCurrency: TokenTypes.TOK,
    providerUrl: 'http://127.0.0.1:7545/',
    icon: SvgPicture.asset('assets/svg/logo-xdai2.svg'),
  );

  // Avalanch (AVAX)
  static const int AVALANCHE_CHAINID = 43114;
  static Chain Avalanche = Chain(
    chainId: AVALANCHE_CHAINID,
    name: "Avalanche Mainnet",
    nativeCurrency: TokenTypes.AVAX,
    providerUrl: 'https://api.avax.network/ext/bc/C/rpc',
    //icon: SvgPicture.asset('assets/svg/logo-xdai2.svg'),
    explorerUrl: 'https://snowtrace.io/',
  );

  // Binance Smart Chain (BSC)
  static const int BSC_CHAINID = 56;
  static Chain BinanceSmartChain = Chain(
    chainId: BSC_CHAINID,
    name: "Binance Smart Chain",
    nativeCurrency: TokenTypes.BNB,
    providerUrl: 'https://bsc-dataseed1.binance.org',
    //icon: SvgPicture.asset('assets/svg/logo-xdai2.svg'),
    explorerUrl: 'https://bscscan.com',
  );

  // Polygon (MATIC)
  static const int POLYGON_CHAINID = 137;
  static Chain Polygon = Chain(
    chainId: POLYGON_CHAINID,
    name: "Polygon Chain",
    nativeCurrency: TokenTypes.MATIC,
    providerUrl: 'https://polygon-rpc.com/',
    //icon: SvgPicture.asset('assets/svg/logo-xdai2.svg'),
    explorerUrl: 'https://polygonscan.com/',
  );

  /*
  TODO: We would need a price source for AETH
  // Arbitrum One
  static const int ARBITRUM_ONE_CHAINID = 42161;
  static Chain ArbitrumOne = Chain(
    chainId: ARBITRUM_ONE_CHAINID,
    name: "Arbitrum One",
    nativeCurrency: TokenTypes.AETH,
    providerUrl: 'https://arb1.arbitrum.io/rpc/',
    //icon: SvgPicture.asset('assets/svg/logo-xdai2.svg'),
    explorerUrl: 'https://arbiscan.io/',
  );
   */

  static Map<int, Chain> map = {
    Ethereum.chainId: Ethereum,
    xDAI.chainId: xDAI,
    GanacheTest.chainId: GanacheTest,
    Avalanche.chainId: Avalanche,
    BinanceSmartChain.chainId: BinanceSmartChain,
    Polygon.chainId: Polygon,
  };

  static bool isKnown(int chainId) {
    return map[chainId] != null;
  }

  // Get the chain for chainId
  static Chain chainFor(int chainId) {
    var chain = map[chainId];
    if (chain == null) {
      throw Exception("no chain for chainId: $chainId");
    }
    return chain;
  }
}

class Chain {
  final int chainId;
  final String name;
  final TokenType nativeCurrency;
  final String providerUrl;

  /// Optional icon svg
  final SvgPicture icon;

  /// Optional explorer URL
  final String explorerUrl;

  const Chain({
    @required this.chainId,
    @required this.name,
    @required this.nativeCurrency,
    @required this.providerUrl,
    this.icon,
    this.explorerUrl,
  });

  Future<Token> getGasPrice({bool refresh = false}) {
    return OrchidEthereumV1().getGasPrice(this, refresh: refresh);
  }

  int get requiredConfirmations {
    return isGanache ? 1 : 2;
  }

  bool get isGanache {
    return this == Chains.GanacheTest;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chain &&
          runtimeType == other.runtimeType &&
          chainId == other.chainId;

  @override
  int get hashCode => chainId.hashCode;

  @override
  String toString() {
    return 'Chain{chainId: $chainId, name: $name}';
  }
}
