import 'package:orchid/api/orchid_eth/token_type.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:orchid/api/orchid_log_api.dart';
import 'package:orchid/util/cacheable.dart';
import 'package:orchid/util/units.dart';

import '../orchid_platform.dart';

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

  /// The USD price for the token. (USD/Token)
  Future<double> usdPrice(TokenType tokenType) async {
    return tokenToUsdRate(tokenType);
  }

  /// (USD/Token): Tokens * Rate = USD
  Future<double> tokenToUsdRate(TokenType tokenType) async {
    if (tokenType.exchangeRateSource == TokenTypes.NoExchangeRateSource) {
      throw Exception('No exchange rate source for token: ${tokenType.symbol}');
    }

    return cache.get(
        key: tokenType,
        producer: (tokenType) {
          return tokenType.exchangeRateSource.tokenToUsdRate(tokenType);
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
}

abstract class ExchangeRateSource {
  final String symbolOverride;

  const ExchangeRateSource({this.symbolOverride});

  /// Return the price (USD/Token): tokens * Rate = USD
  Future<double> tokenToUsdRate(TokenType tokenType);

  Future<double> _invert(double rate) async {
    if (rate == 0) {
      throw Exception("invalid rate: $rate");
    }
    return 1.0 / rate;
  }
}

class BinanceExchangeRateSource extends ExchangeRateSource {
  /// A Binance lookup is normally <TOKEN>USDT:
  /// https://api.binance.com/api/v3/avgPrice?symbol=ETHUSDT
  ///
  /// This flag reverses the pair ordering to USDT<TOKEN> and inverts
  /// the rate consistent with that. e.g. for DAI we must use 1/USDTDAI and
  /// not DAIUSDT since DAIUSDT was delisted.
  final bool inverted;

  const BinanceExchangeRateSource(
      {this.inverted = false, String symbolOverride})
      : super(symbolOverride: symbolOverride); // Binance exchange rates

  // https://api.binance.com/api/v3/avgPrice?symbol=ETHUSDT
  String _url(TokenType tokenType) {
    var symbol = symbolOverride ?? tokenType.symbol.toUpperCase();
    var pair = inverted ? 'USDT$symbol' : '${symbol}USDT';
    return 'https://api.binance.com/api/v3/avgPrice?symbol=$pair';
  }

  /// Return the rate USD/Token: Tokens * Rate = USD
  Future<double> tokenToUsdRate(TokenType tokenType) async {
    var rate = await _getPrice(tokenType);
    return inverted ? _invert(rate) : rate;
  }

  Future<double> _getPrice(TokenType tokenType) async {
    logDetail("pricing: Binance fetching rate for: $tokenType");
    try {
      var response = await http.get(
        _url(tokenType),
        headers: OrchidPlatform.isWeb
            ? {}
            : {'Referer': 'https://account.orchid.com'},
      );
      if (response.statusCode != 200) {
        throw Exception("Error status code: ${response.statusCode}");
      }
      var body = json.decode(response.body);
      return double.parse(body['price']);
    } catch (err) {
      log("Error fetching pricing: $err");
      throw err;
    }
  }
}
