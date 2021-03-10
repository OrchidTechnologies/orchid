import 'package:orchid/util/units.dart';

import '../orchid_log_api.dart';

class StaticExchangeRates {
  static USD from({double price, String currencyCode}) {
    double rate = rates[currencyCode];
    log("currency exchange rate: $price in $currencyCode, rate = $rate");
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
    "EUR": 0.84,
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
