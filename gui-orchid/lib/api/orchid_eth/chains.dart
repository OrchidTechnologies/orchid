// ignore_for_file: non_constant_identifier_names
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_user_config/orchid_user_param.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'package:orchid/api/preferences/user_preferences_ui.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'package:orchid/api/pricing/usd.dart';
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
    var jsConfig = OrchidUserConfig().getUserConfig();
    // Note: This var is also used by the tunnel for the eth provider.
    return jsConfig.evalStringDefault('rpc', _defaultEthereumProviderUrl);
  }

  static Chain unknownChain(int chainId) {
    return Chain(
      chainId: chainId,
      name: "Unknown",
      defaultProviderUrl: '',
      iconPath: OrchidAssetSvgChain.unknown_chain_path,
      blocktime: 0,
      eip1559: false,

      // unknown token type
      nativeCurrency: TokenType(
        symbol: 'TOK',
        exchangeRateSource: FixedPriceToken.zero,
        chainId: chainId,
        iconPath: OrchidAssetSvgToken.unknown_token_path,
      ),
    );
  }

  // Ganache Test
  static const int GANACHE_TEST_CHAINID = 1337;
  static Chain GanacheTest = Chain(
    chainId: GANACHE_TEST_CHAINID,
    name: 'Ganache',
    nativeCurrency: Tokens.TOK,
    defaultProviderUrl: 'http://127.0.0.1:7545/',
    iconPath: OrchidAssetSvgChain.unknown_chain_path,
    blocktime: 0,
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
    blocktime: 12,
  );

  // Gnosis (xDAI)
  // xDai Chain has been rebranded to Gnosis Chain
  static const int GNOSIS_CHAINID = 100;
  static Chain Gnosis = Chain(
    chainId: GNOSIS_CHAINID,
    name: 'Gnosis',
    nativeCurrency: Tokens.XDAI,
    defaultProviderUrl: 'https://rpc.gnosis.gateway.fm',
    iconPath: OrchidAssetSvgChain.gnossis_chain_path,
    explorerUrl: 'https://blockscout.com/xdai/mainnet/',
    supportsLogs: true,
    blocktime: 5,
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
    blocktime: 3,
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
    blocktime: 3,
    eip1559: false,
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
    blocktime: 2,
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
    blocktime: 0,
    // non-standard transaction structure...
    eip1559: false,
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
    blocktime: 0,
  );

  // Aurora (NEAR)
  static const int AURORA_CHAINID = 1313161554;
  static Chain Aurora = Chain(
    chainId: AURORA_CHAINID,
    name: 'Aurora',
    nativeCurrency: Tokens.AURORA_ETH,
    defaultProviderUrl: 'https://mainnet.aurora.dev',
    iconPath: OrchidAssetSvgChain.near_aurora_chain_path,
    explorerUrl: 'https://explorer.aurora.dev/',
    // Additional L1 fees.
    hasNonstandardTransactionFees: true,
    supportsLogs: true,
    blocktime: 1,
    eip1559: false,
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
    blocktime: 1,
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
    blocktime: 0.5,
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
    blocktime: 0,
    eip1559: false,
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
    blocktime: 5,
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

  static Map<int, Chain> get knownChains {
    return _map;
  }

  static Map<int, Chain> get userConfiguredChains {
    return UserPreferencesUI()
        .userConfiguredChains
        .get()!
        .toMap(withKey: (e) => e.chainId, withValue: (e) => e);
  }

  /// The map of supported chains, filtered to remove disabled chains.
  static Map<int, Chain> get map {
    // Remove disabled chains
    final Iterable<int> disabled = UserPreferencesUI()
        .chainConfig
        .get()!
        .where((e) => !e.enabled)
        .map((e) => e.chainId);
    Map<int, Chain> map = Map.of(knownChains);
    map.removeWhere((key, _) => disabled.contains(key));
    map.addAll(userConfiguredChains);

    return map;
  }

  static bool isKnown(int chainId) {
    if (OrchidUserParams().newchain) {
      return false;
    }
    return knownChains[chainId] != null;
  }

  // Get the chain for chainId
  static Chain chainFor(int chainId) {
    if (OrchidUserParams().newchain) {
      return unknownChain(chainId);
    }

    var chain = knownChains[chainId];
    if (chain == null) {
      return unknownChain(chainId);
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
  final double blocktime; // average, seconds
  final bool eip1559;

  /// Indicates that transaction may incur additional fees outside the standard
  /// gas fees.
  // TODO: This should evolve into a description of how to estimate those fees.
  final bool hasNonstandardTransactionFees;

  SvgPicture get icon {
    return SvgPicture.asset(iconPath);
  }

  /// Optional explorer URL
  final String? explorerUrl;

  const Chain({
    required this.chainId,
    required this.name,
    required this.nativeCurrency,
    required this.defaultProviderUrl,
    required this.blocktime,
    this.requiredConfirmations = 1,
    required this.iconPath,
    this.explorerUrl,
    this.hasNonstandardTransactionFees = false,
    this.supportsLogs = false,
    this.eip1559 = true,
  });

  String get providerUrl {
    final config = UserPreferencesUI().chainConfigFor(chainId);

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

  bool get isKnown {
    return Chains.isKnown(chainId);
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
    return 'Chain{chainId: $chainId, name: $name, nativeCurrency: $nativeCurrency, defaultProviderUrl: $defaultProviderUrl, requiredConfirmations: $requiredConfirmations, supportsLogs: $supportsLogs, iconPath: $iconPath, hasNonstandardTransactionFees: $hasNonstandardTransactionFees, explorerUrl: $explorerUrl}';
  }
}

class UserConfiguredChain extends Chain {
  UserConfiguredChain({
    required String name,
    required int chainId,
    required String defaultProviderUrl,
    required USD tokenPriceUSD,
  }) : super(
            chainId: chainId,
            name: name,
            defaultProviderUrl: defaultProviderUrl,
            nativeCurrency: userConfiguredTokenType(chainId, tokenPriceUSD),
            blocktime: 0,
            eip1559: false,
            iconPath: OrchidAssetSvgChain.unknown_chain_path);

  UserConfiguredChain.fromJson(Map<String, dynamic> json)
      : this(
          name: json['name'],
          chainId: json['chainId'],
          defaultProviderUrl: json['url'],
          tokenPriceUSD: USD(double.parse(json['tokenPrice'])),
        );

  Map<String, dynamic> toJson() => {
        'name': name,
        'chainId': chainId,
        'url': defaultProviderUrl,
        // TODO: FixedToken price USD
        'tokenPrice': (nativeCurrency.exchangeRateSource as FixedPriceToken)
            .usdPrice
            .value
            .toString(),
      };

  static TokenType userConfiguredTokenType(int chainId, USD tokenPriceUSD) {
    return TokenType(
      symbol: 'TOK',
      // TODO: Support a more general user-specified pricing source
      exchangeRateSource: FixedPriceToken(tokenPriceUSD),
      chainId: chainId,
      // TODO: Support user-pasted chain SVG.
      iconPath: OrchidAssetSvgToken.unknown_token_path,
    );
  }

  @override
  String get iconPath => OrchidAssetSvgChain.unknown_chain_path;

  // TODO: Support user-pasted chain SVG.
  SvgPicture get icon {
    return SvgPicture.asset(iconPath);
  }

  @override
  bool get supportsLogs => false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is UserConfiguredChain &&
          runtimeType == other.runtimeType;

  @override
  int get hashCode => super.hashCode;
}
