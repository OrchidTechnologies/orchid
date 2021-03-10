import 'package:flutter/foundation.dart';
import 'package:orchid/util/units.dart';

/// A purchased access credit with a localized price and product id.
class PAC {
  String productId;
  double localPurchasePrice;
  String localCurrencyCode; // e.g. "USD"
  String localDisplayPrice;
  USD usdPriceApproximate;

  PAC({
    @required this.productId,
    @required this.localPurchasePrice,
    @required this.localCurrencyCode,
    @required this.localDisplayPrice,
    @required this.usdPriceApproximate,
  });

  @override
  String toString() {
    return 'PAC{_productId: $productId, localPurchasePrice: $localPurchasePrice, localDisplayName: $localDisplayPrice}, usdPriceApproximate: $usdPriceApproximate';
  }
}
