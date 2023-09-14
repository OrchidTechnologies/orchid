import 'dart:ui';
import 'package:intl/intl.dart';

String toFixedLocalized(num value,
    {int precision = 2, String ifNull = "...", required Locale locale}) {
  return formatCurrency(value,
      locale: locale, ifNull: ifNull, precision: precision);
}

/// Format a currency to default precision with an optional suffix and null behavior.
String formatCurrency(
  num? value, {
  String? suffix,

  /// The exact number of digits, possibly zero padded, to display after the decimal.
  /// If minPrecision and maxPrecision are specified this value is ignored.
  /// e.g. 1.00, 1.01
  int precision = 2,

  /// If minPrecision and maxPrecision are specified the value shows the required number
  /// of digits after the decimal with a minimum (zero padded) and up to the maximum provided.
  /// e.g. 1.0, 1.123456789
  int? maxPrecision,
  int? minPrecision,

  /// If true show ellipsis when full precision is not shown
  bool showPrecisionIndicator = false,
  String ifNull = "...",
  required Locale locale,
}) {
  if (value == null) {
    return ifNull;
  }

  final suffixPadded = (suffix != null ? " $suffix" : "");

  // min/max precision
  if (minPrecision != null && maxPrecision != null) {
    final format =
        "#0." + "0" * minPrecision + "#" * (maxPrecision - minPrecision);

    final restricted =
        NumberFormat(format, locale.toLanguageTag()).format(value);

    var precisionIndicator = '';
    if (showPrecisionIndicator) {
      const ellipsis = '…';
      final unrestricted =
          NumberFormat("#0." + "#" * 16, locale.toLanguageTag()).format(value);
      precisionIndicator =
          restricted.length < unrestricted.length ? ellipsis : '';
    }

    return restricted + precisionIndicator + suffixPadded;
  }
  // fixed precision
  else {
    final format = "#0." + "0" * precision;
    return NumberFormat(format, locale.toLanguageTag()).format(value) +
        suffixPadded;
  }
}
