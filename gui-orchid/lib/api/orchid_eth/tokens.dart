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
    iconPath: OrchidAssetToken.ethereum_eth_token,
  );

  static TokenType OXT = TokenType(
    symbol: 'OXT',
    exchangeRateSource: BinanceExchangeRateSource(),
    chainId: Chains.ETH_CHAINID,
    erc20Address: OrchidContractV0.oxtContractAddress,
    iconPath: OrchidAssetToken.orchid_oxt_token,
  );

  static const TokenType XDAI = TokenType(
    symbol: 'xDAI',
    // Binance lists DAIUSDT but the value is bogus. The real pair is USDTDAI, so invert.
    exchangeRateSource:
        BinanceExchangeRateSource(symbolOverride: 'DAI', inverted: true),
    chainId: Chains.XDAI_CHAINID,
    iconPath: OrchidAssetToken.xdai_token,
  );

  static const TokenType TOK = TokenType(
    symbol: 'TOK',
    exchangeRateSource: ETHExchangeRateSource,
    chainId: Chains.GANACHE_TEST_CHAINID,
    iconPath: OrchidAssetToken.unknown_token,
  );

  static const TokenType AVAX = TokenType(
    symbol: 'AVAX',
    exchangeRateSource: BinanceExchangeRateSource(),
    chainId: Chains.AVALANCHE_CHAINID,
    iconPath: OrchidAssetToken.avalanche_avax_token,
  );

  static const TokenType BNB = TokenType(
    symbol: 'BNB',
    exchangeRateSource: BinanceExchangeRateSource(),
    chainId: Chains.BSC_CHAINID,
    iconPath: OrchidAssetToken.binance_coin_bnb_token,
  );

  static const TokenType MATIC = TokenType(
    symbol: 'MATIC',
    exchangeRateSource: BinanceExchangeRateSource(),
    chainId: Chains.POLYGON_CHAINID,
    iconPath: OrchidAssetToken.matic_token,
  );

  static const TokenType OETH = TokenType(
    symbol: 'ETH',
    // OETH is ETH on L2
    exchangeRateSource: ETHExchangeRateSource,
    chainId: Chains.OPTIMISM_CHAINID,
    iconPath: OrchidAssetToken.ethereum_eth_token,
  );

  // Aurora is an L2 on Near
  static const TokenType AURORA_ETH = TokenType(
    symbol: 'ETH',
    // aETH should ultimately track the price of ETH
    exchangeRateSource: ETHExchangeRateSource,
    chainId: Chains.AURORA_CHAINID,
    iconPath: OrchidAssetToken.ethereum_eth_token,
  );

  static const TokenType ARBITRUM_ETH = TokenType(
    symbol: 'ETH',
    // AETH is ETH on L2
    exchangeRateSource: ETHExchangeRateSource,
    chainId: Chains.ARBITRUM_ONE_CHAINID,
    iconPath: OrchidAssetToken.ethereum_eth_token,
  );

  static const TokenType FTM = TokenType(
    symbol: 'FTM',
    exchangeRateSource: BinanceExchangeRateSource(),
    chainId: Chains.FANTOM_CHAINID,
    iconPath: OrchidAssetToken.fantom_ftm_token,
  );

  static const TokenType TLOS = TokenType(
    symbol: 'TLOS',
    exchangeRateSource: NoExchangeRateSource,
    chainId: Chains.TELOS_CHAINID,
    iconPath: OrchidAssetToken.telos_tlos_token,
  );

  static const TokenType RBTC = TokenType(
    symbol: 'RTBC',
    exchangeRateSource: BinanceExchangeRateSource(symbolOverride: 'BTC'),
    chainId: Chains.RSK_CHAINID,
    iconPath: OrchidAssetToken.bitcoin_btc_token,
  );
}
