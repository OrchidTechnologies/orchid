import 'dart:math';

import 'package:orchid/api/orchid_budget_api.dart';
import 'package:orchid/api/orchid_eth.dart';
import 'package:orchid/util/units.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  static int gasCostToRedeemTicket = 100000;

  /// Calculate the current real world value of the largest ticket that can be
  /// issued from this lottery pot, taking into account the amount of gas required
  /// to redeem the ticket, current gas prices, and the OXT-ETH exchange rate.
  /// Returns the net value in OXT, which may be zero or negative if the ticket
  /// would be unprofitable to redeem.
  Future<OXT> getMaxTicketValue(LotteryPot pot) async {
    Pricing pricing = await getPricing();
    GWEI gasPrice = await OrchidEthereum().getGasPrice();
    ETH gasCostToRedeem = (gasPrice * gasCostToRedeemTicket).toEth();
    OXT oxtCostToRedeem = pricing.ethToOxt(gasCostToRedeem);
    OXT maxFaceValue = OXT.min(pot.balance, pot.deposit/ 2.0);
    return maxFaceValue - oxtCostToRedeem;
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
    return USD(oxt.value * oxtToUsdRate);
  }

  OXT toOXT(USD usd) {
    if (usd == null) {
      return null;
    }
    return OXT(usd.value / oxtToUsdRate);
  }

  OXT ethToOxt(ETH eth) {
    return OXT(oxtToUsdRate / ethToUsdRate * eth.value);
  }

  @override
  String toString() {
    return 'Pricing{date: $date, ethToUsdRate: $ethToUsdRate, oxtToUsdRate: $oxtToUsdRate}';
  }
}
