import 'package:orchid/api/orchid_eth/token_type.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/util/cacheable.dart';
import 'package:orchid/util/collections.dart';
import 'orchid_pricing.dart';

class CoinGeckoExchangeRateSource extends ExchangeRateSource {
  final String tokenId;

  const CoinGeckoExchangeRateSource({required this.tokenId});

  /// Return the price, USD/Token: Tokens * Rate = USD
  Future<double> tokenToUsdRate(TokenType tokenType) async {
    final prices = await cache.get(producer: () async {
      return await _getPrices();
    });
    logDetail("XXX: coingecko prices = $prices");
    // TODO: Need to propagate nulls through the API including our cache.
    return prices[tokenType] ?? 0;
  }

  // Since we are fetching the entire list of coins in one call, cache them here.
  static SingleCache<Map<TokenType, double?>> cache =
      SingleCache(duration: Duration(seconds: 300), name: "coingecko pricing");

  static List<TokenType> get _tokens {
    return Tokens.all
        .where((e) => e.exchangeRateSource is CoinGeckoExchangeRateSource)
        .toList();
  }

  // e.g. ids="ethereum,orchid-protocol,bitcoin,xdai,matic-network,avalanche-2,binancecoin,celo,fantom"
  // https://api.coingecko.com/api/v3/simple/price?ids='"$ids"'&vs_currencies=USD
  static String get _url {
    String tokenIds = _tokens
        .map((e) => e.exchangeRateSource)
        .cast<CoinGeckoExchangeRateSource>()
        .map((e) => e.tokenId)
        .join(',');
    return 'https://api.coingecko.com/api/v3/simple/price?ids=$tokenIds&vs_currencies=USD';
  }

  static Future<Map<TokenType, double?>> _getPrices() async {
    final url = _url;
    logDetail("XXX: coingecko pricing: fetching rates, url = $url");
    try {
      var response = await http.get(
        Uri.parse(url),
        // headers: OrchidPlatform.isWeb ? {} : {'Referer': 'https://account.orchid.com'},
      );
      if (response.statusCode != 200) {
        throw Exception("Error status code: ${response.statusCode}");
      }
      var _json = json.decode(response.body);
      return _tokens.toMap(
          withKey: (token) => token,
          withValue: (token) {
            try {
              final tokenId =
                  (token.exchangeRateSource as CoinGeckoExchangeRateSource)
                      .tokenId;
              return _json[tokenId]["usd"];
            } catch (err) {
              logDetail(
                  "XXX: Err in coingecko pricing: missing token price: $err");
              return null;
            }
          });
    } catch (err) {
      log("coingecko pricing: Error fetching pricing: $err");
      throw err;
    }
  }
}
