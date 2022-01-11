// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'token_type.dart';
import 'package:orchid/util/collections.dart';

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

  // Ganache Test
  static const String unknownLogoPath =
      'assets/svg/chains/unknown-token-logo.svg';
  static const int GANACHE_TEST_CHAINID = 1337;
  static Chain GanacheTest = Chain(
    chainId: GANACHE_TEST_CHAINID,
    name: "Ganache Test",
    nativeCurrency: TokenTypes.TOK,
    providerUrl: 'http://127.0.0.1:7545/',
    iconPath: unknownLogoPath,
  );

  // Ethereum (ETH)
  static const int ETH_CHAINID = 1;
  static const String ethIconPath = 'assets/svg/chains/ethereum-eth-logo.svg';
  static Chain Ethereum = Chain(
    chainId: ETH_CHAINID,
    name: "Ethereum",
    nativeCurrency: TokenTypes.ETH,
    providerUrl: defaultEthereumProviderUrl,
    iconPath: ethIconPath,
    supportsLogs: true,
  );

  // Gnosis (xDAI)
  // xDai Chain has been rebranded to Gnosis Chain
  static const int XDAI_CHAINID = 100;
  static Chain xDAI = Chain(
    chainId: XDAI_CHAINID,
    name: "Gnosis Chain",
    nativeCurrency: TokenTypes.XDAI,
    // providerUrl: 'https://dai.poa.network',
    providerUrl: 'https://rpc.xdaichain.com/',
    iconPath: 'assets/svg/chains/gnosis-chain-white.svg',
    supportsLogs: true,
  );

  // Avalanch (AVAX)
  static const int AVALANCHE_CHAINID = 43114;
  static Chain Avalanche = Chain(
    chainId: AVALANCHE_CHAINID,
    name: "Avalanche Chain",
    nativeCurrency: TokenTypes.AVAX,
    providerUrl: 'https://api.avax.network/ext/bc/C/rpc',
    iconPath: 'assets/svg/chains/avalanche-avax-logo.svg',
    explorerUrl: 'https://snowtrace.io/',
    supportsLogs: true,
  );

  // Binance Smart Chain (BSC)
  static const int BSC_CHAINID = 56;
  static Chain BinanceSmartChain = Chain(
    chainId: BSC_CHAINID,
    name: "Binance Smart Chain",
    nativeCurrency: TokenTypes.BNB,
    providerUrl: 'https://bsc-dataseed1.binance.org',
    iconPath: 'assets/svg/chains/binance-coin-bnb-logo.svg',
    explorerUrl: 'https://bscscan.com',
  );

  // Polygon (MATIC)
  static const int POLYGON_CHAINID = 137;
  static Chain Polygon = Chain(
    chainId: POLYGON_CHAINID,
    name: "Polygon Chain",
    nativeCurrency: TokenTypes.MATIC,
    providerUrl: 'https://polygon-rpc.com/',
    iconPath: 'assets/svg/chains/matic-token-icon1.svg',
    explorerUrl: 'https://polygonscan.com/',
  );

  // Optimism (OETH)
  static const int OPTIMISM_CHAINID = 10;
  static Chain Optimism = Chain(
    chainId: OPTIMISM_CHAINID,
    name: "Optimism Chain",
    nativeCurrency: TokenTypes.OETH,
    providerUrl: 'https://mainnet.optimism.io/',
    iconPath: 'assets/svg/chains/optimism-logo.svg',
    explorerUrl: 'https://optimistic.etherscan.io',
    // Additional L1 fees.
    hasNonstandardTransactionFees: true,
    supportsLogs: true,
  );

  // Arbitrum One (AETH)
  static const int ARBITRUM_ONE_CHAINID = 42161;
  static Chain ArbitrumOne = Chain(
    chainId: ARBITRUM_ONE_CHAINID,
    name: "Arbitrum One",
    nativeCurrency: TokenTypes.ARBITRUM_ETH,
    providerUrl: 'https://arb1.arbitrum.io/rpc/',
    // TODO: missing real icon
    iconPath: unknownLogoPath,
    explorerUrl: 'https://arbiscan.io/',
  );

  // Aurora (NEAR)
  static const int AURORA_CHAINID = 1313161554;
  static Chain Aurora = Chain(
    chainId: AURORA_CHAINID,
    name: "Aurora Chain",
    nativeCurrency: TokenTypes.AURORA_ETH,
    providerUrl: 'https://mainnet.aurora.dev',
    iconPath: 'assets/svg/chains/near-logo.svg',
    // TODO: Missing explorer URL
    explorerUrl: 'https://',
    // Additional L1 fees.
    hasNonstandardTransactionFees: true,
    supportsLogs: true,
  );

  // Fantom (FTM)
  static const int FANTOM_CHAINID = 250;
  static Chain Fantom = Chain(
    chainId: FANTOM_CHAINID,
    name: "Fantom Chain",
    nativeCurrency: TokenTypes.FTM,
    providerUrl: 'https://rpc.ftm.tools',
    iconPath: 'assets/svg/chains/fantom-token.svg',
    explorerUrl: 'https://ftmscan.com',
    supportsLogs: true,
  );

  // Telos (TLOS)
  static const int TELOS_CHAINID = 40;
  static Chain Telos = Chain(
    chainId: TELOS_CHAINID,
    name: "Telos Chain",
    nativeCurrency: TokenTypes.TLOS,
    providerUrl: 'https://mainnet.telos.net/evm',
    iconPath: 'assets/svg/chains/TLOS-logo.svg',
    explorerUrl: 'https://teloscan.io',
  );

  static Map<int, Chain> map = [
    GanacheTest,
    Ethereum,
    xDAI,
    Avalanche,
    BinanceSmartChain,
    Polygon,
    Optimism,
    ArbitrumOne,
    Aurora,
    Fantom,
    Telos,
  ].toMap(withKey: (e) => e.chainId, withValue: (e) => e);

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
  final int requiredConfirmations;
  final bool supportsLogs;

  /// Optional icon svg
  final String iconPath;

  /// Indicates that transaction may incur additional fees outside the standard
  /// gas fees.
  // TODO: This should evolve into a description of how to estimate those fees.
  final bool hasNonstandardTransactionFees;

  SvgPicture get icon {
    return SvgPicture.asset(iconPath);
  }

  /// Optional explorer URL
  final String explorerUrl;

  const Chain({
    @required this.chainId,
    @required this.name,
    @required this.nativeCurrency,
    @required this.providerUrl,
    this.requiredConfirmations = 1,
    this.iconPath,
    this.explorerUrl,
    this.hasNonstandardTransactionFees = false,
    this.supportsLogs = false,
  });

  Future<Token> getGasPrice({bool refresh = false}) {
    // The gas price call is generic and works for V0 and V1
    return OrchidEthereumV1().getGasPrice(this, refresh: refresh);
  }

  bool get isGanache {
    return this == Chains.GanacheTest;
  }

  bool get isEthereum {
    return this == Chains.Ethereum;
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
