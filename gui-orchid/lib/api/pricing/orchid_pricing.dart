import 'package:flutter/foundation.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/util/cacheable.dart';
import 'package:orchid/api/pricing/usd.dart';

/// Token Exchange rates
class OrchidPricing {
  static OrchidPricing _shared = OrchidPricing._init();

  Cache<TokenType, double> cache =
      Cache(duration: Duration(seconds: 30), name: "pricing");

  OrchidPricing._init();

  factory OrchidPricing() {
    return _shared;
  }

  /// The USD value of the token quantity.
  Future<USD> tokenToUSD(Token token) async {
    return USD(token.floatValue * await tokenToUsdRate(token.type));
  }

  /// Convert value of from token to equivalant USD value in 'to' token type.
  Future<Token> tokenToToken(Token fromToken, TokenType toType) async {
    return toType.fromDouble(
        fromToken.floatValue * await tokenToTokenRate(fromToken.type, toType));
  }

  /// (toType / fromType): The conversion rate from fromType to toType
  Future<double> tokenToTokenRate(TokenType fromType, TokenType toType) async {
    // (to/usd) / (from/usd) = to/from
    return await usdToTokenRate(toType) / await usdToTokenRate(fromType);
  }

  // TODO: change return type to USD
  /// The USD price for the token. (USD/Token)
  Future<double> usdPrice(TokenType tokenType) async {
    return tokenToUsdRate(tokenType);
  }

  /// (USD/Token): Tokens * Rate = USD
  Future<double> tokenToUsdRate(TokenType tokenType) async {
    if (tokenType.exchangeRateSource == null) {
      throw Exception('No exchange rate source for token: ${tokenType.symbol}');
    }

    return cache.get(
        key: tokenType,
        producer: (tokenType) {
          return tokenType.exchangeRateSource!.tokenToUsdRate(tokenType);
        });
  }

  /// (Token/USD): USD * Rate = Tokens
  Future<double> usdToTokenRate(TokenType tokenType) async {
    var rate = await tokenToUsdRate(tokenType);
    if (rate == 0) {
      throw Exception("invalid rate: $rate");
    }
    return 1.0 / rate;
  }

  static logTokenPrices() async {
    String out = "Token Prices:\n";
    for (var token in Tokens.all) {
      out += "${token.symbol}:  \$${await token.exchangeRateSource?.tokenToUsdRate(token)}\n";
    }
    log(out);
  }
}

abstract class ExchangeRateSource {
  const ExchangeRateSource();

  /// Return the price (USD/Token): tokens * Rate = USD
  Future<double> tokenToUsdRate(TokenType tokenType);

  @protected
  Future<double> invert(double rate) async {
    if (rate == 0) {
      throw Exception("invalid rate: $rate");
    }
    return 1.0 / rate;
  }
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
