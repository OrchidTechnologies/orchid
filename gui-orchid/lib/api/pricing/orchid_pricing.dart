import 'package:orchid/api/orchid_eth/token_type.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:orchid/api/orchid_log_api.dart';

/// Token Exchange rates
class OrchidPricing {
  static OrchidPricing _shared = OrchidPricing._init();

  static Duration cacheDuration = Duration(seconds: 30);

  OrchidPricing._init();

  factory OrchidPricing() {
    return _shared;
  }

  Map<TokenType, _CachedRate> _cache = Map();

  /// Return the rate USD/Token: TokenType * Rate = USD
  Future<double> tokenToUsdRate(TokenType tokenType) async {
    var cached = _cache[tokenType];
    if (cached != null && cached.newerThan(cacheDuration)) {
      log("pricing: returning cached rate for: $tokenType");
      return cached.rate;
    }

    var rate = await tokenType.exchangeRateSource.tokenToUsdRate(tokenType);
    _cache[tokenType] = _CachedRate(rate);
    return rate;
  }

  Future<double> usdToTokenRate(TokenType tokenType) async {
    var rate = await tokenToUsdRate(tokenType);
    if (rate == 0) {
      throw Exception("invalid rate: $rate");
    }
    return 1.0 / rate;
  }
}

class _CachedRate {
  DateTime time = DateTime.now();
  double rate;

  _CachedRate(this.rate);

  bool newerThan(Duration duration) {
    return DateTime.now().difference(time) < duration;
  }
}

abstract class ExchangeRateSource {
  final String symbolOverride;

  const ExchangeRateSource({this.symbolOverride});

  /// Return the rate USD/Token: Tokens * Rate = USD
  Future<double> tokenToUsdRate(TokenType tokenType);

  Future<double> _invert(double rate) async {
    if (rate == 0) {
      throw Exception("invalid rate: $rate");
    }
    return 1.0 / rate;
  }
}

class BinanceExchangeRateSource extends ExchangeRateSource {
  /// Reverse the default <TOKEN>USDT pair ordering to USDT<TOKEN> and invert
  /// the rate consistent with that. e.g. for DAI we must use 1/USDTDAI and
  /// not DAIUSDT since DAIUSDT was delisted.
  final bool inverted;

  const BinanceExchangeRateSource(
      {this.inverted = false, String symbolOverride})
      : super(symbolOverride: symbolOverride); // Binance exchange rates

  // https://api.binance.com/api/v3/avgPrice?symbol=ETHUSDT
  String url(TokenType tokenType) {
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
    log("pricing: Binance fetching rate for: $tokenType");
    try {
      var response = await http.get(url(tokenType),
          headers: {'referer': 'https://account.orchid.com'});
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
