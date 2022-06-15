// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'token_type.dart';
import 'package:orchid/util/collections.dart';
import 'tokens.dart';

// Some chain data from https://github.com/ethereum-lists/chains
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

  // Get the provider URL allowing override in the advanced config
  static String get _overriddenEthereumProviderUrl {
    var jsConfig = OrchidUserConfig().getUserConfigJS();
    // Note: This var is also used by the tunnel for the eth provider.
    return jsConfig.evalStringDefault('rpc', _defaultEthereumProviderUrl);
  }

  // Ganache Test
  static const int GANACHE_TEST_CHAINID = 1337;
  static Chain GanacheTest = Chain(
    chainId: GANACHE_TEST_CHAINID,
    name: 'Ganache',
    nativeCurrency: Tokens.TOK,
    defaultProviderUrl: 'http://127.0.0.1:7545/',
    iconPath: OrchidAssetSvgChain.unknown_chain_path,
  );

  // Ethereum (ETH)
  static const int ETH_CHAINID = 1;
  static String ethIconPath = OrchidAssetSvgToken.ethereum_eth_token_path;
  static Chain Ethereum = Chain(
    chainId: ETH_CHAINID,
    name: 'Ethereum',
    nativeCurrency: Tokens.ETH,
    defaultProviderUrl: _overriddenEthereumProviderUrl,
    iconPath: ethIconPath,
    explorerUrl: 'https://etherscan.io/',
    supportsLogs: true,
  );

  // Gnosis (xDAI)
  // xDai Chain has been rebranded to Gnosis Chain
  static const int GNOSIS_CHAINID = 100;
  static Chain Gnosis = Chain(
    chainId: GNOSIS_CHAINID,
    name: 'Gnosis',
    nativeCurrency: Tokens.XDAI,
    defaultProviderUrl: 'https://rpc.gnosischain.com/',
    iconPath: OrchidAssetSvgChain.gnossis_chain_path,
    explorerUrl: 'https://blockscout.com/xdai/mainnet/',
    supportsLogs: true,
  );

  // Avalanch (AVAX)
  static const int AVALANCHE_CHAINID = 43114;
  static Chain Avalanche = Chain(
    chainId: AVALANCHE_CHAINID,
    name: 'Avalanche',
    nativeCurrency: Tokens.AVAX,
    defaultProviderUrl: 'https://api.avax.network/ext/bc/C/rpc',
    iconPath: OrchidAssetSvgToken.avalanche_avax_token_path,
    explorerUrl: 'https://snowtrace.io/',
    supportsLogs: false,
  );

  // Binance Smart Chain (BSC)
  static const int BSC_CHAINID = 56;
  static Chain BinanceSmartChain = Chain(
    chainId: BSC_CHAINID,
    name: 'Binance',
    nativeCurrency: Tokens.BNB,
    defaultProviderUrl: 'https://bsc-dataseed1.binance.org',
    iconPath: OrchidAssetSvgChain.binance_smart_chain_path,
    explorerUrl: 'https://bscscan.com',
  );

  // Polygon (MATIC)
  static const int POLYGON_CHAINID = 137;
  static Chain Polygon = Chain(
    chainId: POLYGON_CHAINID,
    name: 'Polygon',
    nativeCurrency: Tokens.MATIC,
    defaultProviderUrl: 'https://polygon-rpc.com/',
    iconPath: OrchidAssetSvgToken.matic_token_path,
    explorerUrl: 'https://polygonscan.com/',
  );

  // Optimism (OETH)
  static const int OPTIMISM_CHAINID = 10;
  static Chain Optimism = Chain(
    chainId: OPTIMISM_CHAINID,
    name: 'Optimism',
    nativeCurrency: Tokens.OETH,
    defaultProviderUrl: 'https://mainnet.optimism.io/',
    iconPath: OrchidAssetSvgChain.optimism_chain_path,
    explorerUrl: 'https://optimistic.etherscan.io',
    // Additional L1 fees.
    hasNonstandardTransactionFees: true,
    supportsLogs: true,
  );

  // Arbitrum One (AETH)
  static const int ARBITRUM_ONE_CHAINID = 42161;
  static Chain ArbitrumOne = Chain(
    chainId: ARBITRUM_ONE_CHAINID,
    name: 'Arbitrum One',
    nativeCurrency: Tokens.ARBITRUM_ETH,
    defaultProviderUrl: 'https://arb1.arbitrum.io/rpc/',
    // TODO: missing chain icon
    iconPath: OrchidAssetSvgChain.unknown_chain_path,
    explorerUrl: 'https://arbiscan.io/',
  );

  // Aurora (NEAR)
  static const int AURORA_CHAINID = 1313161554;
  static Chain Aurora = Chain(
    chainId: AURORA_CHAINID,
    name: 'Aurora',
    nativeCurrency: Tokens.AURORA_ETH,
    defaultProviderUrl: 'https://mainnet.aurora.dev',
    iconPath: OrchidAssetSvgChain.near_aurora_chain_path,
    // TODO: Missing explorer URL
    // Additional L1 fees.
    hasNonstandardTransactionFees: true,
    supportsLogs: true,
  );

  // Fantom (FTM)
  static const int FANTOM_CHAINID = 250;
  static Chain Fantom = Chain(
    chainId: FANTOM_CHAINID,
    name: 'Fantom',
    nativeCurrency: Tokens.FTM,
    defaultProviderUrl: 'https://rpc.ftm.tools',
    iconPath: OrchidAssetSvgToken.fantom_ftm_token_path,
    explorerUrl: 'https://ftmscan.com',
    supportsLogs: true,
  );

  // Telos (TLOS)
  static const int TELOS_CHAINID = 40;
  static Chain Telos = Chain(
    chainId: TELOS_CHAINID,
    name: 'Telos',
    nativeCurrency: Tokens.TLOS,
    defaultProviderUrl: 'https://mainnet.telos.net/evm',
    iconPath: OrchidAssetSvgToken.telos_tlos_token_path,
    explorerUrl: 'https://teloscan.io',
  );

// RSK (BTC)
  static const int RSK_CHAINID = 30;
  static Chain RSK = Chain(
    chainId: RSK_CHAINID,
    name: 'RSK',
    nativeCurrency: Tokens.RBTC,
    defaultProviderUrl: 'https://public-node.rsk.co',
    iconPath: OrchidAssetSvgChain.rsk_chain_path,
    explorerUrl: 'https://explorer.rsk.co',
  );

  // Celo (CELO)
  static const int CELO_CHAINID = 42220;
  static Chain Celo = Chain(
    chainId: CELO_CHAINID,
    name: 'CELO',
    nativeCurrency: Tokens.CELO,
    defaultProviderUrl: 'https://forno.celo.org',
    iconPath: OrchidAssetSvgChain.celo_chain_path,
    explorerUrl: 'https://explorer.celo.org',
  );

  static Map<int, Chain> _map = [
    Aurora,
    Avalanche,
    BinanceSmartChain,
    Celo,
    Ethereum,
    Fantom,
    GanacheTest,
    Gnosis,
    Optimism,
    Polygon,
    // ArbitrumOne,
    // RSK,
    // Telos,
  ].toMap(withKey: (e) => e.chainId, withValue: (e) => e);

  static Map<int, Chain> get unfiltered {
    return _map;
  }

  /// The map of supported chains, filtered to remove disabled chains.
  static Map<int, Chain> get map {
    // Remove disabled chains
    final disabled = UserPreferences()
        .chainConfig
        .get()
        .where((e) => !e.enabled)
        .map((e) => e.chainId);
    var map = Map.of(_map);
    map.removeWhere((key, _) => disabled.contains(key));
    return map;
  }

  static bool isKnown(int chainId) {
    return unfiltered[chainId] != null;
  }

  // Get the chain for chainId
  static Chain chainFor(int chainId) {
    var chain = unfiltered[chainId];
    if (chain == null) {
      throw Exception('no chain for chainId: $chainId');
    }
    return chain;
  }
}

class Chain {
  final int chainId;
  final String name;
  final TokenType nativeCurrency;
  final String defaultProviderUrl;
  final int requiredConfirmations;
  final bool supportsLogs;
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
    @required this.defaultProviderUrl,
    this.requiredConfirmations = 1,
    this.iconPath,
    this.explorerUrl,
    this.hasNonstandardTransactionFees = false,
    this.supportsLogs = false,
  });

  String get providerUrl {
    final config = UserPreferences().chainConfigFor(chainId);

    // TODO: Decide what we do with configured hops.
    // Prevent any usage of the chain if the user has it disabled.
    // if (config?.enabled == false) {
    //   throw Exception('chain disabled');
    // }

    return config?.rpcUrl ?? defaultProviderUrl;
  }

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
