// ignore_for_file: non_constant_identifier_names
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'chains.dart';
import 'token_type.dart';

class Tokens {
  // Indicates that we do not have a source for pricing information for the token.
  static const ExchangeRateSource NoExchangeRateSource = null;

  // Override the symbol to ETH so that ETH-equivalent tokens care share this.
  static const ETHExchangeRateSource =
      BinanceExchangeRateSource(symbolOverride: 'ETH');

  static const TokenType ETH = TokenType(
    symbol: 'ETH',
    exchangeRateSource: ETHExchangeRateSource,
    chainId: Chains.ETH_CHAINID,
    iconPath: OrchidAssetSvgToken.ethereum_eth_token_path,
  );

  static TokenType OXT = TokenType(
    symbol: 'OXT',
    exchangeRateSource: BinanceExchangeRateSource(),
    chainId: Chains.ETH_CHAINID,
    erc20Address: OrchidContractV0.oxtContractAddress,
    iconPath: OrchidAssetSvgToken.orchid_oxt_token_path,
  );

  static const TokenType XDAI = TokenType(
    symbol: 'xDAI',
    // Binance lists DAIUSDT but the value is bogus. The real pair is USDTDAI, so invert.
    exchangeRateSource:
        BinanceExchangeRateSource(symbolOverride: 'DAI', inverted: true),
    chainId: Chains.GNOSIS_CHAINID,
    iconPath: OrchidAssetSvgToken.xdai_token_path,
  );

  static const TokenType TOK = TokenType(
    symbol: 'TOK',
    exchangeRateSource: ZeroPriceToken(),
    chainId: Chains.GANACHE_TEST_CHAINID,
    iconPath: OrchidAssetSvgToken.unknown_token_path,
  );

  static const TokenType AVAX = TokenType(
    symbol: 'AVAX',
    exchangeRateSource: BinanceExchangeRateSource(),
    chainId: Chains.AVALANCHE_CHAINID,
    iconPath: OrchidAssetSvgToken.avalanche_avax_token_path,
  );

  static const TokenType BNB = TokenType(
    symbol: 'BNB',
    exchangeRateSource: BinanceExchangeRateSource(),
    chainId: Chains.BSC_CHAINID,
    iconPath: OrchidAssetSvgToken.binance_coin_bnb_token_path,
  );

  static const TokenType MATIC = TokenType(
    symbol: 'MATIC',
    exchangeRateSource: BinanceExchangeRateSource(),
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
    exchangeRateSource: BinanceExchangeRateSource(),
    chainId: Chains.FANTOM_CHAINID,
    iconPath: OrchidAssetSvgToken.fantom_ftm_token_path,
  );

  static const TokenType TLOS = TokenType(
    symbol: 'TLOS',
    exchangeRateSource: NoExchangeRateSource,
    chainId: Chains.TELOS_CHAINID,
    iconPath: OrchidAssetSvgToken.telos_tlos_token_path,
  );

  static const TokenType RBTC = TokenType(
    symbol: 'RTBC',
    exchangeRateSource: BinanceExchangeRateSource(symbolOverride: 'BTC'),
    chainId: Chains.RSK_CHAINID,
    iconPath: OrchidAssetSvgToken.bitcoin_btc_token_path,
  );

  static const TokenType CELO = TokenType(
    symbol: 'CELO',
    exchangeRateSource: BinanceExchangeRateSource(),
    chainId: Chains.CELO_CHAINID,
    iconPath: OrchidAssetSvgToken.celo_token_path,
  );
}

class ZeroPriceToken extends ExchangeRateSource {

  const ZeroPriceToken();

  @override
  Future<double> tokenToUsdRate(TokenType tokenType) async {
    return 0;
  }

}
