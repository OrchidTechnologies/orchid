import 'package:orchid/util/units.dart';

/// Exchange rates
class OrchidPricingAPI {
  static OrchidPricingAPI _shared = OrchidPricingAPI._init();

  OrchidPricingAPI._init() {}

  factory OrchidPricingAPI() {
    return _shared;
  }

  /// Get a snapshot of current pricing data with an associated "as of" time.
  /// This method may return null if no pricing data is available and the UI
  /// should handle this as a routine condition by hiding displayed conversions.
  /// (The app may ship without pricing enabled at some point).
  Future<Pricing> getPricing() async {
//    return null;
    // TODO: Placeholder, need a service
    return Pricing(oxtToUsdRate: 0.5);
  }
}

/// Pricing captures exchange rates at a point in time and supports conversion.
class Pricing {
  DateTime asOf;
  double oxtToUsdRate = 0.5;

  Pricing({DateTime asOf, double oxtToUsdRate}) {
    this.asOf = asOf ?? DateTime.now();
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
}
