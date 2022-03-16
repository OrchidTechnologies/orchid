// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'token_type.dart';
import 'package:orchid/util/collections.dart';

import 'tokens.dart';

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
  static const int GANACHE_TEST_CHAINID = 1337;
  static Chain GanacheTest = Chain(
    chainId: GANACHE_TEST_CHAINID,
    name: 'Ganache',
    nativeCurrency: Tokens.TOK,
    providerUrl: 'http://127.0.0.1:7545/',
    iconPath: OrchidAssetSvgChain.unknown_chain_path,
  );

  // Ethereum (ETH)
  static const int ETH_CHAINID = 1;
  static String ethIconPath = OrchidAssetSvgToken.ethereum_eth_token_path;
  static Chain Ethereum = Chain(
    chainId: ETH_CHAINID,
    name: 'Ethereum',
    nativeCurrency: Tokens.ETH,
    providerUrl: defaultEthereumProviderUrl,
    iconPath: ethIconPath,
    supportsLogs: true,
  );

  // Gnosis (xDAI)
  // xDai Chain has been rebranded to Gnosis Chain
  static const int XDAI_CHAINID = 100;
  static Chain xDAI = Chain(
    chainId: XDAI_CHAINID,
    name: 'Gnosis',
    nativeCurrency: Tokens.XDAI,
    // providerUrl: 'https://rpc.xdaichain.com/',
    providerUrl: 'https://rpc.gnosischain.com/',
    iconPath: OrchidAssetSvgChain.gnossis_chain_path,
    explorerUrl: 'https://blockscout.com/xdai/mainnet/',
    supportsLogs: true,
  );

  // Avalanch (AVAX)
  static const int AVALANCHE_CHAINID = 43114;
  static Chain Avalanche = Chain(
    chainId: AVALANCHE_CHAINID,
    name: 'Avalanche Network',
    nativeCurrency: Tokens.AVAX,
    providerUrl: 'https://api.avax.network/ext/bc/C/rpc',
    iconPath: OrchidAssetSvgToken.avalanche_avax_token_path,
    explorerUrl: 'https://snowtrace.io/',
    supportsLogs: true,
  );

  // Binance Smart Chain (BSC)
  static const int BSC_CHAINID = 56;
  static Chain BinanceSmartChain = Chain(
    chainId: BSC_CHAINID,
    name: 'Binance Smart Chain',
    nativeCurrency: Tokens.BNB,
    providerUrl: 'https://bsc-dataseed1.binance.org',
    iconPath: OrchidAssetSvgChain.binance_smart_chain_path,
    explorerUrl: 'https://bscscan.com',
  );

  // Polygon (MATIC)
  static const int POLYGON_CHAINID = 137;
  static Chain Polygon = Chain(
    chainId: POLYGON_CHAINID,
    name: 'Polygon',
    nativeCurrency: Tokens.MATIC,
    providerUrl: 'https://polygon-rpc.com/',
    iconPath: OrchidAssetSvgToken.matic_token_path,
    explorerUrl: 'https://polygonscan.com/',
  );

  // Optimism (OETH)
  static const int OPTIMISM_CHAINID = 10;
  static Chain Optimism = Chain(
    chainId: OPTIMISM_CHAINID,
    name: 'Optimism',
    nativeCurrency: Tokens.OETH,
    providerUrl: 'https://mainnet.optimism.io/',
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
    providerUrl: 'https://arb1.arbitrum.io/rpc/',
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
    providerUrl: 'https://mainnet.aurora.dev',
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
    providerUrl: 'https://rpc.ftm.tools',
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
    providerUrl: 'https://mainnet.telos.net/evm',
    iconPath: OrchidAssetSvgToken.telos_tlos_token_path,
    explorerUrl: 'https://teloscan.io',
  );

  static const int RSK_CHAINID = 30;
  static Chain RSK = Chain(
    chainId: RSK_CHAINID,
    name: 'RSK',
    nativeCurrency: Tokens.RBTC,
    providerUrl: 'https://public-node.rsk.co',
    iconPath: OrchidAssetSvgChain.rsk_chain_path,
    explorerUrl: 'https://explorer.rsk.co',
  );

  static Map<int, Chain> map = [
    GanacheTest,
    Ethereum,
    xDAI,
    Avalanche,
    BinanceSmartChain,
    Polygon,
    Optimism,
    Aurora,
    Fantom,
    // ArbitrumOne,
    // RSK,
    // Telos,
  ].toMap(withKey: (e) => e.chainId, withValue: (e) => e);

  static bool isKnown(int chainId) {
    return map[chainId] != null;
  }

  // Get the chain for chainId
  static Chain chainFor(int chainId) {
    var chain = map[chainId];
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
  final String providerUrl;
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
