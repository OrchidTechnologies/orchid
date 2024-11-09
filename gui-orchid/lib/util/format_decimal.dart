import 'dart:ui';
import 'package:decimal/decimal.dart';
import 'package:decimal/intl.dart';
import 'package:intl/intl.dart';

// Legacy-named helper method for formatting decimal with a fixed precision.
String toFixedLocalized(double value,
    {int precision = 2, String ifNull = "...", required Locale locale}) {
  return formatDouble(value,
      locale: locale, ifNull: ifNull, precision: precision);
}

/// Format a double to default precision with an optional suffix (units) and null behavior.
String formatDouble(
  double? value, {
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
          NumberFormat("#0." + "#" * 18, locale.toLanguageTag()).format(value);
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

// Note: This is the same logic as formatDouble but there are intl issues preventing
// Note: us from combining the two more at the moment. (see below)
/// Format a decimal to default precision with an optional suffix (units) and null behavior.
String formatDecimal(
  Decimal? value, {
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

  // Force 'min' fixed digits (e.g. zeroes) after the decimal and then allow up to 'max' fractional digits total.
  if (minPrecision != null && maxPrecision != null) {
    final format =
        "#0." + "0" * minPrecision + "#" * (maxPrecision - minPrecision);

    /// BUG: There is an issue with the decimal package intl integration.
    /// "WARNING: For now (2024.05.30) intl doesn't work with "
    /// "NumberFormat.maximumFractionDigits greater than 15 on web plateform and 18 otherwise."
    // final restricted = DecimalFormatter(NumberFormat(format, locale.toLanguageTag())).format(value);
    // Workaround: no internationalization at this stage
    var restricted = value.toStringAsFixed(maxPrecision);

    // Implement the min/max manually
    restricted = trimAndPadDecimal(restricted, minPrecision, maxPrecision);
    print("XXX: restricted: $restricted");

    var precisionIndicator = '';
    if (showPrecisionIndicator) {
      const ellipsis = '…';

      /// BUG: There is an issue with the decimal package intl integration.
      /// "WARNING: For now (2024.05.30) intl doesn't work with "
      /// "NumberFormat.maximumFractionDigits greater than 15 on web plateform and 18 otherwise."
      // final unrestricted = DecimalFormatter(
      //         NumberFormat("#0." + "#" * 18, locale.toLanguageTag()))
      //     .format(value);
      // Workaround: no internationalization at this stage
      final unrestricted = value.toString();

      print("XXX: unrestricted: $unrestricted");
      precisionIndicator =
          restricted.length < unrestricted.length ? ellipsis : '';
    }

    // Hack some basic internationalization
    // replace '.' with the locale-specific decimal separator
    final decimalSeparator =
        NumberFormat.decimalPattern(locale.toString()).symbols.DECIMAL_SEP;
    restricted = restricted.replaceFirst('.', decimalSeparator);

    return restricted + precisionIndicator + suffixPadded;
  }
  // fixed precision
  else {
    final format = "#0." + "0" * precision;
    return DecimalFormatter(NumberFormat(format, locale.toLanguageTag()))
            .format(value) +
        suffixPadded;
  }
}

// Temporary workaround for the lack of intl formatting support for long decimals
// in the decimal package (see above).
String trimAndPadDecimal(String value, int minPrecision, int maxPrecision) {
  // Handle cases where the value is just '0' or '0.' or '0.0...'
  if (value == "0" || value.replaceAll("0", "") == ".") {
    value = "0";
  }

  // Ensure there's a decimal point for further processing
  if (!value.contains('.')) {
    value += '.';
  }

  // Split into integer and fractional parts
  List<String> parts = value.split('.');
  String integerPart = parts[0].isEmpty ? '0' : parts[0];
  String fractionalPart = parts.length > 1 ? parts[1] : '';

  // Apply maxPrecision: truncate if necessary
  if (fractionalPart.length > maxPrecision) {
    fractionalPart = fractionalPart.substring(0, maxPrecision);
  }

  // Apply minPrecision: pad with zeros if necessary
  while (fractionalPart.length < minPrecision) {
    fractionalPart += '0';
  }

  // Remove trailing zeros beyond minPrecision
  if (fractionalPart.length > minPrecision) {
    fractionalPart = fractionalPart.replaceAll(RegExp(r'0+$'), '');
  }

  // If the fractional part is empty, return just the integer part with minPrecision zeros
  if (fractionalPart.isEmpty) {
    fractionalPart = '0' * minPrecision;
  }

  return '$integerPart.$fractionalPart';
}
