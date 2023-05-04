// @dart=2.12
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_eth_v1.dart';
import 'orchid_pricing.dart';

/// This source uses a dollar stablecoin vs ETH to infer the price of ETH
class UniswapETHPriceSource extends ExchangeRateSource {
  final int dollarPoolTokenDecimals; // token0
  final String dollarTokenVsETHPoolAddress;

  const UniswapETHPriceSource({
    this.dollarPoolTokenDecimals = 18,
    required this.dollarTokenVsETHPoolAddress,
  });

  /// Note: tokenType is unused in this implementation as it is determined by the pool.
  Future<double?> tokenToUsdRate(TokenType _) async {
    double token0Price = await OrchidEthereumV1().getUniswapPrice(
        dollarTokenVsETHPoolAddress, dollarPoolTokenDecimals, 18 /*ETH*/);
    return 1.0 / (token0Price + 1e-9);
  }
}

/// Use a token vs ETH pool to infer the price
class UniswapPriceSource extends ExchangeRateSource {
  final int poolTokenDecimals; // token0
  final String tokenVsETHPoolAddress;
  final ExchangeRateSource ethPriceSource;

  const UniswapPriceSource({
    this.poolTokenDecimals = 18,
    required this.tokenVsETHPoolAddress,
    this.ethPriceSource = Tokens.ETHPriceSource,
  });

  /// Return the price, USD/Token: Tokens * Rate = USD
  /// Note: tokenType is unused in this implementation as it is determined by the pool.
  // Note: results are cached by the caller.
  Future<double?> tokenToUsdRate(TokenType _) async {
    double price = await OrchidEthereumV1()
        .getUniswapPrice(tokenVsETHPoolAddress, poolTokenDecimals, 18 /*ETH*/);
    double ethPrice = await ethPriceSource.tokenToUsdRate(Tokens.ETH);
    return price * ethPrice;
  }
}
