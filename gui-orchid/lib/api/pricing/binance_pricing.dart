import 'package:orchid/api/orchid_eth/token_type.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'orchid_pricing.dart';

class BinanceExchangeRateSource extends ExchangeRateSource {
  /// A Binance lookup is normally <TOKEN>USDT:
  /// https://api.binance.com/api/v3/avgPrice?symbol=ETHUSDT
  ///
  /// This flag reverses the pair ordering to USDT<TOKEN> and inverts
  /// the rate consistent with that. e.g. for DAI we must use 1/USDTDAI and
  /// not DAIUSDT since DAIUSDT was delisted.
  final bool inverted;
  final String? symbolOverride;

  const BinanceExchangeRateSource({this.inverted = false, this.symbolOverride});

  // https://api.binance.com/api/v3/avgPrice?symbol=ETHUSDT
  String _url(TokenType tokenType) {
    var symbol = symbolOverride ?? tokenType.symbol.toUpperCase();
    var pair = inverted ? 'USDT$symbol' : '${symbol}USDT';
    return 'https://api.binance.com/api/v3/avgPrice?symbol=$pair';
  }

  /// Return the price, USD/Token: Tokens * Rate = USD
  Future<double> tokenToUsdRate(TokenType tokenType) async {
    double rate = await _getPrice(tokenType);
    return inverted ? await invert(rate) : rate;
  }

  Future<double> _getPrice(TokenType tokenType) async {
    logDetail("pricing: Binance fetching rate for: $tokenType");
    try {
      var response = await http.get(
        Uri.parse(_url(tokenType)),
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
