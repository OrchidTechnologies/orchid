import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/api/pricing/usd.dart';

/// Token Exchange rates
@deprecated
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
  Future<PricingV0?> getPricing() async {
    try {
      return PricingV0(
        ethPriceUSD: await OrchidPricing().usdPrice(Tokens.ETH),
        oxtPriceUSD: await OrchidPricing().usdPrice(Tokens.OXT),
      );
    } catch (err) {
      print("Error fetching pricing: $err");
      return null;
    }
  }
}

/// Pricing captures exchange rates at a point in time and supports conversion.
@deprecated
class PricingV0 {
  final DateTime date;

  // dollars per eth
  double ethPriceUSD;

  // dollars per oxt
  double oxtPriceUSD;

  PricingV0({
    DateTime? date,
    // dollars per eth
    required this.ethPriceUSD,
    // dollars per oxt
    required this.oxtPriceUSD,
  }) : this.date = date ?? DateTime.now();

  USD? toUSD(OXT? oxt) {
    if (oxt == null) {
      return null;
    }
    return USD(oxt.floatValue * oxtPriceUSD);
  }

  OXT? toOXT(USD? usd) {
    if (usd == null) {
      return null;
    }
    return OXT.fromDouble(usd.value / oxtPriceUSD);
  }

  OXT ethToOxt(ETH eth) {
    // ($/eth) / ($/oxt)  = oxt/eth
    var value = OXT.fromDouble(ethPriceUSD / oxtPriceUSD * eth.value);
    return value;
  }

  // Note: workaround until we get rid of ETH type.
  OXT ethToOxtToken(Token eth) {
    return ethToOxt(ETH.fromWei(eth.intValue));
  }

  @override
  String toString() {
    return 'PricingV0{date: $date, ethPriceUSD: $ethPriceUSD, oxtPriceUSD: $oxtPriceUSD}';
  }
}
