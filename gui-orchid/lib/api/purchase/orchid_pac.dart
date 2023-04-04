// @dart=2.9
import 'package:flutter/foundation.dart';
import 'package:orchid/util/units.dart';
import 'package:intl/intl.dart';

/// A purchased access credit with a localized price and product id.
class PAC {
  final String productId;
  final double localPrice;
  final String localCurrencyCode; // e.g. 'USD'
  final String localCurrencySymbol; // e.g. '$'
  final USD usdPriceExact;

  /// Format the local price as a currency value with symbol.
  // e.g. "$1.99"
  String get localDisplayPrice {
    return formatCurrency(localPrice);
  }

  /// Format a currency value with symbol.
  String formatCurrency(double value) {
    return NumberFormat.currency(symbol: localCurrencySymbol).format(value);
  }

  PAC({
    @required this.productId,
    @required this.localPrice,
    @required this.localCurrencyCode,
    @required this.localCurrencySymbol,
    @required this.usdPriceExact,
  });

  @override
  String toString() {
    return 'PAC{_productId: $productId, localPurchasePrice: $localPrice, localDisplayName: $localDisplayPrice}, usdPriceExact: $usdPriceExact';
  }
}
