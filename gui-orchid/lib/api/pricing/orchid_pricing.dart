import 'package:orchid/api/orchid_eth/token_type.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:orchid/api/orchid_log_api.dart';

/// Token Exchange rates
class OrchidPricing {
  static OrchidPricing _shared = OrchidPricing._init();

  static Duration cacheDuration = Duration(seconds: 30);

  // Binance exchange rates
  // https://api.binance.com/api/v3/avgPrice?symbol=ETHUSDT
  static String url(TokenType tokenType) {
    var symbol = tokenType.exchangeRateSymbol;
    return 'https://api.binance.com/api/v3/avgPrice?symbol=${symbol}USDT';
  }

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

    log("pricing: Fetching rate for: $tokenType");
    try {
      var response = await http
          .get(url(tokenType), headers: {'referer': 'https://account.orchid.com'});
      if (response.statusCode != 200) {
        throw Exception("Error status code: ${response.statusCode}");
      }
      var body = json.decode(response.body);
      var rate = double.parse(body['price']);
      _cache[tokenType] = _CachedRate(rate);

      return rate;
    } catch (err) {
      log("Error fetching pricing: $err");
      throw err;
    }
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
