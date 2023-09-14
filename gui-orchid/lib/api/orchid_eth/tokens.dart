// ignore_for_file: non_constant_identifier_names
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/pricing/coingecko_pricing.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/api/pricing/uniswap_pricing.dart';
import 'package:orchid/orchid/orchid_asset.dart';
import 'package:orchid/api/pricing/usd.dart';
import 'chains.dart';
import 'token_type.dart';
export 'tokens_legacy.dart';

class Tokens {

  static const ETHPriceSource = const UniswapETHPriceSource(
    // USDC / ETH 0.3%
    dollarTokenVsETHPoolAddress: USDCVsETHPoolAddress,
    dollarPoolTokenDecimals: USDC_DECIMALS,
  );

  static const TokenType ETH = TokenType(
    symbol: 'ETH',
    exchangeRateSource: ETHPriceSource,
    chainId: Chains.ETH_CHAINID,
    iconPath: OrchidAssetSvgToken.ethereum_eth_token_path,
  );

  static TokenType OXT = TokenType(
    symbol: 'OXT',
    exchangeRateSource: UniswapPriceSource(
        // OXT / ETH 1%
        tokenVsETHPoolAddress: '0x820e5ab3d952901165f858703ae968e5ea67eb31'),
    chainId: Chains.ETH_CHAINID,
    erc20Address: OrchidContractV0.oxtContractAddress,
    iconPath: OrchidAssetSvgToken.orchid_oxt_token_path,
  );

  static TokenType XDAI = TokenType(
    symbol: 'xDAI',
    configSymbolOverride: 'DAI',
    exchangeRateSource: UniswapPriceSource(
      //  DAI / ETH 0.05%
      tokenVsETHPoolAddress: '0x60594a405d53811d3BC4766596EFD80fd545A270',
    ),
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
    exchangeRateSource: UniswapPriceSource(
      //  WAVAX / ETH 0.3%
      tokenVsETHPoolAddress: '0x00C6A247a868dEE7e84d16eBa22D1Ab903108a44',
    ),
    chainId: Chains.AVALANCHE_CHAINID,
    iconPath: OrchidAssetSvgToken.avalanche_avax_token_path,
  );

  static const TokenType BNB = TokenType(
    symbol: 'BNB',
    exchangeRateSource: UniswapPriceSource(
      //  WBNB / ETH 0.3%
      tokenVsETHPoolAddress: '0xba8080b0b09181e09bca0612b22b9475d8171055',
    ),
    chainId: Chains.BSC_CHAINID,
    iconPath: OrchidAssetSvgToken.binance_coin_bnb_token_path,
  );

  static const TokenType MATIC = TokenType(
    symbol: 'MATIC',
    exchangeRateSource: UniswapPriceSource(
      //  MATIC / ETH 0.3%
      tokenVsETHPoolAddress: '0x290a6a7460b308ee3f19023d2d00de604bcf5b42',
    ),
    chainId: Chains.POLYGON_CHAINID,
    iconPath: OrchidAssetSvgToken.matic_token_path,
  );

  static const TokenType OETH = TokenType(
    symbol: 'ETH',
    // OETH is ETH on L2
    exchangeRateSource: ETHPriceSource,
    chainId: Chains.OPTIMISM_CHAINID,
    iconPath: OrchidAssetSvgToken.ethereum_eth_token_path,
  );

  // Aurora is an L2 on Near
  static const TokenType AURORA_ETH = TokenType(
    symbol: 'ETH',
    // aETH is ETH on L2
    exchangeRateSource: ETHPriceSource,
    chainId: Chains.AURORA_CHAINID,
    iconPath: OrchidAssetSvgToken.ethereum_eth_token_path,
  );

  static const TokenType ARBITRUM_ETH = TokenType(
    symbol: 'ETH',
    // AETH is ETH on L2
    exchangeRateSource: ETHPriceSource,
    chainId: Chains.ARBITRUM_ONE_CHAINID,
    iconPath: OrchidAssetSvgToken.ethereum_eth_token_path,
  );

  static const TokenType FTM = TokenType(
    symbol: 'FTM',
    exchangeRateSource: UniswapPriceSource(
      //  FTM / ETH 1%
      tokenVsETHPoolAddress: '0x3b685307c8611afb2a9e83ebc8743dc20480716e',
    ),
    chainId: Chains.FANTOM_CHAINID,
    iconPath: OrchidAssetSvgToken.fantom_ftm_token_path,
  );

  static const TokenType TLOS = TokenType(
    symbol: 'TLOS',
    exchangeRateSource: UniswapPriceSource(
      //  TLOS / ETH 0.3%
      tokenVsETHPoolAddress: '0x27dd7b7D610c9BE6620A893B51d0F7856C6f3bfD',
    ),
    chainId: Chains.TELOS_CHAINID,
    iconPath: OrchidAssetSvgToken.telos_tlos_token_path,
  );

  static const TokenType RBTC = TokenType(
    symbol: 'RTBC',
    configSymbolOverride: 'BTC',
    exchangeRateSource: UniswapPriceSource(
      // WBTC / ETH 0.05%
      tokenVsETHPoolAddress: '0x4585fe77225b41b697c938b018e2ac67ac5a20c0',
    ),
    chainId: Chains.RSK_CHAINID,
    iconPath: OrchidAssetSvgToken.bitcoin_btc_token_path,
  );

  static const TokenType CELO = TokenType(
    symbol: 'CELO',
    // Looking for a Uniswap pool... not finding one.
    exchangeRateSource: CoinGeckoExchangeRateSource(tokenId: 'celo'),
    chainId: Chains.CELO_CHAINID,
    iconPath: OrchidAssetSvgToken.celo_token_path,
  );

  static const USDCVsETHPoolAddress =
      '0x8ad599c3A0ff1De082011EFDDc58f1908eb6e6D8';
  static const USDC_DECIMALS = 6;
  static const TokenType USDC = TokenType(
    symbol: 'USDC',
    // For purposes of pricing using Uniswap pools we have to have at least one
    // reference token that is externally priced or assumed. For now we will fix USDC at $1.
    exchangeRateSource: FixedPriceToken(USD(1.00)),
    chainId: Chains.ETH_CHAINID,
    iconPath: OrchidAssetSvgToken.unknown_token_path,
    decimals: USDC_DECIMALS,
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

