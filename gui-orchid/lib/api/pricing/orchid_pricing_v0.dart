
import 'package:orchid/util/units.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Token Exchange rates
class OrchidPricingAPIV0 {
  static OrchidPricingAPIV0 _shared = OrchidPricingAPIV0._init();
  static var exchangeRatesProviderUrl =
      'https://api.coinbase.com/v2/exchange-rates';

  OrchidPricingAPIV0._init();

  factory OrchidPricingAPIV0() {
    return _shared;
  }

  PricingV0 _lastPricing;

  /// Get a snapshot of current pricing data at the current time.
  /// This method may return null if no pricing data is available and the UI
  /// should handle this as a routine condition by hiding displayed conversions.
  /// This method is cached for a period of time and safe to call repeatedly.
  Future<PricingV0> getPricing() async {
    // Cache for a period of time
    if (_lastPricing != null &&
        DateTime.now().difference(_lastPricing.date) < Duration(minutes: 5)) {
      return _lastPricing;
    }

    try {
      var response = await http.get(exchangeRatesProviderUrl);
      if (response.statusCode != 200) {
        throw Exception("Error status code: ${response.statusCode}");
      }
      var body = json.decode(response.body);
      var rates = body['data']['rates'];
      _lastPricing = PricingV0(
          ethToUsdRate: double.parse(rates['ETH']),
          oxtToUsdRate: double.parse(rates['OXT']));
      return _lastPricing;
    } catch (err) {
      print("Error fetching pricing: $err");
      return null;
    }
  }

}

/// Pricing captures exchange rates at a point in time and supports conversion.
class PricingV0 {
  DateTime date;
  double ethToUsdRate;
  double oxtToUsdRate;

  PricingV0({
    DateTime date,
    @required double ethToUsdRate,
    @required double oxtToUsdRate,
  }) {
    this.date = date ?? DateTime.now();
    this.ethToUsdRate = ethToUsdRate;
    this.oxtToUsdRate = oxtToUsdRate;
  }

  USD toUSD(OXT oxt) {
    if (oxt == null) {
      return null;
    }
    return USD(oxt.floatValue * oxtToUsdRate);
  }

  OXT toOXT(USD usd) {
    if (usd == null) {
      return null;
    }
    return OXT.fromDouble(usd.value / oxtToUsdRate);
  }

  OXT ethToOxt(ETH eth) {
    return OXT.fromDouble(oxtToUsdRate / ethToUsdRate * eth.value);
  }

  @override
  String toString() {
    return 'Pricing{date: $date, ethToUsdRate: $ethToUsdRate, oxtToUsdRate: $oxtToUsdRate}';
  }
}
