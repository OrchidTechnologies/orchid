import 'dart:math';

import 'package:orchid/util/units.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'orchid_log_api.dart';

/// Exchange rates
class OrchidPricingAPI {
  static OrchidPricingAPI _shared = OrchidPricingAPI._init();
  static var exchangeRatesProviderUrl =
      'https://api.coinbase.com/v2/exchange-rates';

  OrchidPricingAPI._init();

  factory OrchidPricingAPI() {
    return _shared;
  }

  Pricing _lastPricing;

  /// Get a snapshot of current pricing data at the current time.
  /// This method may return null if no pricing data is available and the UI
  /// should handle this as a routine condition by hiding displayed conversions.
  /// This method is cached for a period of time and safe to call repeatedly.
  Future<Pricing> getPricing() async {
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
      _lastPricing = Pricing(
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
class Pricing {
  DateTime date;
  double ethToUsdRate;
  double oxtToUsdRate;

  Pricing({
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

class StaticExchangeRates {
  static USD from({double price, String currencyCode}) {
    double rate = rates[currencyCode];
    if (rate == null) {
      log("iap: conversion rate not found for: $currencyCode");
      return USD(price); // default to 1.0
    }
    return USD(price / rate);
  }

  // dollars * rate = localized price
  static Map<String, double> rates = {
    "AED": 3.58,
    "AUD": 1.57,
    "BGN": 2.14,
    "BRL": 3.56,
    "CAD": 1.43,
    "CHF": 1.00,
    "CLP": 0.64,
    "CNY": 6.44,
    "COP": 3705.29,
    "CZK": 25.61,
    "DKK": 8.44,
    "EGP": 17.17,
    "EUR": 0.93,
    "EUR": 1.14,
    "GBP": 1.00,
    "HKD": 7.58,
    "HRK": 8.58,
    "HUF": 356.22,
    "IDR": 14.16,
    "ILS": 3.71,
    "INR": 78.54,
    "JPY": 123.03,
    "KRW": 1273.25,
    "KZT": 356.22,
    "MXN": 18.45,
    "MYR": 4.28,
    "NGN": 357.65,
    "NOK": 10.73,
    "NZD": 1.72,
    "PEN": 3.28,
    "PHP": 49.93,
    "PKR": 157.37,
    "PLN": 4.72,
    "QAR": 3.58,
    "RON": 5.01,
    "RUB": 75.68,
    "SAR": 3.58,
    "SEK": 9.16,
    "SGD": 1.43,
    "THB": 28.47,
    "TRY": 7.15,
    "TWD": 32.90,
    "TZS": 2131.62,
    "USD": 1.00,
    "VND": 21.32,
    "ZAR": 15.74,
  };
}
