import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/util/units.dart';
import 'package:flutter/foundation.dart';

/// Token Exchange rates
class OrchidPricingAPIV0 {
  static OrchidPricingAPIV0 _shared = OrchidPricingAPIV0._init();

  OrchidPricingAPIV0._init();

  factory OrchidPricingAPIV0() {
    return _shared;
  }

  /// Get a snapshot of current pricing data at the current time.
  /// This method may return null if no pricing data is available and the UI
  /// should handle this as a routine condition by hiding displayed conversions.
  /// This method is cached for a period of time and safe to call repeatedly.
  Future<PricingV0> getPricing() async {
    try {
      return PricingV0(
        ethToUsdRate: await OrchidPricing().tokenToUsdRate(TokenTypes.ETH),
        oxtToUsdRate: await OrchidPricing().tokenToUsdRate(TokenTypes.OXT),
      );
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
