
import 'package:orchid/util/units.dart';

/// Exchange rates
class OrchidPricingAPI
{
  static OrchidPricingAPI _shared = OrchidPricingAPI._init();

  OrchidPricingAPI._init() { }

  factory OrchidPricingAPI() {
    return _shared;
  }

  // TODO: Placeholder, need a service
  Future<Pricing> getPricing() async {
    return Pricing(oxtToUsdRate: 0.5);
  }
}

/// Pricing captures exchange rates at a point in time and supports conversion.
class Pricing
{
  DateTime asOf;
  double oxtToUsdRate = 0.5;

  Pricing({DateTime asOf, double oxtToUsdRate})  {
    this.asOf = asOf ?? DateTime.now();
    this.oxtToUsdRate = oxtToUsdRate;
  }

  USD toUSD(OXT oxt) {
    return USD(oxt.value * oxtToUsdRate);
  }

  OXT toOXT(USD usd) {
    return OXT(usd.value / oxtToUsdRate);
  }
}
