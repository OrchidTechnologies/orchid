// ignore_for_file: non_constant_identifier_names
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/pricing/binance_pricing.dart';
import 'package:orchid/api/pricing/coingecko_pricing.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'package:orchid/util/units.dart';
import 'chains.dart';
import 'token_type.dart';

class Tokens {
  // Indicates that we do not have a source for pricing information for the token.
  static const ExchangeRateSource NoExchangeRateSource = null;

  // Override the symbol to ETH so that ETH-equivalent tokens care share this.
  static const ETHExchangeRateSource =
      CoinGeckoExchangeRateSource(tokenId: 'ethereum');

  static const TokenType ETH = TokenType(
    symbol: 'ETH',
    exchangeRateSource: ETHExchangeRateSource,
    chainId: Chains.ETH_CHAINID,
    iconPath: OrchidAssetSvgToken.ethereum_eth_token_path,
  );

  static TokenType OXT = TokenType(
    symbol: 'OXT',
    exchangeRateSource: CoinGeckoExchangeRateSource(tokenId: 'orchid-protocol'),
    chainId: Chains.ETH_CHAINID,
    erc20Address: OrchidContractV0.oxtContractAddress,
    iconPath: OrchidAssetSvgToken.orchid_oxt_token_path,
  );

  static const TokenType XDAI = TokenType(
    symbol: 'xDAI',
    configSymbolOverride: 'DAI',
    exchangeRateSource: CoinGeckoExchangeRateSource(tokenId: 'xdai'),
    chainId: Chains.GNOSIS_CHAINID,
    iconPath: OrchidAssetSvgToken.xdai_token_path,
  );

  static const TokenType TOK = TokenType(
    symbol: 'TOK',
    exchangeRateSource: FixedPriceToken.zero,
    chainId: Chains.GANACHE_TEST_CHAINID,
    iconPath: OrchidAssetSvgToken.unknown_token_path,
  );

  static const TokenType AVAX = TokenType(
    symbol: 'AVAX',
    exchangeRateSource: CoinGeckoExchangeRateSource(tokenId: 'avalanche-2'),
    chainId: Chains.AVALANCHE_CHAINID,
    iconPath: OrchidAssetSvgToken.avalanche_avax_token_path,
  );

  static const TokenType BNB = TokenType(
    symbol: 'BNB',
    exchangeRateSource: CoinGeckoExchangeRateSource(tokenId: 'binancecoin'),
    chainId: Chains.BSC_CHAINID,
    iconPath: OrchidAssetSvgToken.binance_coin_bnb_token_path,
  );

  static const TokenType MATIC = TokenType(
    symbol: 'MATIC',
    exchangeRateSource: CoinGeckoExchangeRateSource(tokenId: 'matic-network'),
    chainId: Chains.POLYGON_CHAINID,
    iconPath: OrchidAssetSvgToken.matic_token_path,
  );

  static const TokenType OETH = TokenType(
    symbol: 'ETH',
    // OETH is ETH on L2
    exchangeRateSource: ETHExchangeRateSource,
    chainId: Chains.OPTIMISM_CHAINID,
    iconPath: OrchidAssetSvgToken.ethereum_eth_token_path,
  );

  // Aurora is an L2 on Near
  static const TokenType AURORA_ETH = TokenType(
    symbol: 'ETH',
    // aETH should ultimately track the price of ETH
    exchangeRateSource: ETHExchangeRateSource,
    chainId: Chains.AURORA_CHAINID,
    iconPath: OrchidAssetSvgToken.ethereum_eth_token_path,
  );

  static const TokenType ARBITRUM_ETH = TokenType(
    symbol: 'ETH',
    // AETH is ETH on L2
    exchangeRateSource: ETHExchangeRateSource,
    chainId: Chains.ARBITRUM_ONE_CHAINID,
    iconPath: OrchidAssetSvgToken.ethereum_eth_token_path,
  );

  static const TokenType FTM = TokenType(
    symbol: 'FTM',
    exchangeRateSource: CoinGeckoExchangeRateSource(tokenId: 'fantom'),
    chainId: Chains.FANTOM_CHAINID,
    iconPath: OrchidAssetSvgToken.fantom_ftm_token_path,
  );

  static const TokenType TLOS = TokenType(
    symbol: 'TLOS',
    exchangeRateSource: CoinGeckoExchangeRateSource(tokenId: 'telos'),
    chainId: Chains.TELOS_CHAINID,
    iconPath: OrchidAssetSvgToken.telos_tlos_token_path,
  );

  static const TokenType RBTC = TokenType(
    symbol: 'RTBC',
    configSymbolOverride: 'BTC',
    exchangeRateSource: CoinGeckoExchangeRateSource(tokenId: 'bitcoin'),
    chainId: Chains.RSK_CHAINID,
    iconPath: OrchidAssetSvgToken.bitcoin_btc_token_path,
  );

  static const TokenType CELO = TokenType(
    symbol: 'CELO',
    exchangeRateSource: CoinGeckoExchangeRateSource(tokenId: 'celo'),
    chainId: Chains.CELO_CHAINID,
    iconPath: OrchidAssetSvgToken.celo_token_path,
  );

  static List<TokenType> all = [
    ETH,
    OXT,
    XDAI,
    TOK,
    AVAX,
    BNB,
    MATIC,
    OETH,
    AURORA_ETH,
    FTM,
    CELO,
    // ARBITRUM_ETH,
    // RBTC,
    // TLOS,
  ];
}

class FixedPriceToken extends ExchangeRateSource {
  final USD usdPrice;

  static const zero = const FixedPriceToken(USD.zero);

  const FixedPriceToken(this.usdPrice);

  @override
  Future<double> tokenToUsdRate(TokenType tokenType) async {
    return usdPrice.value;
  }
}
