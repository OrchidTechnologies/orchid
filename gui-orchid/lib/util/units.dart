// @dart=2.9
import 'package:orchid/orchid.dart';
import 'package:intl/intl.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';

class ScalarValue<T extends num> {
  final T value;

  const ScalarValue(this.value);

  String toString() {
    return value.toString();
  }

  // Note: This is *not* locale sensitive. See NumberFormat.
  // @See formatCurrency()
  String toStringAsFixed(int len) {
    return value.toStringAsFixed(len);
  }

  bool operator ==(o) => o is ScalarValue<T> && o.value == value;

  int get hashCode => value.hashCode;
}

// Support migration of legacy code and clarify explicit usage of OXT.
// Note: Dart's type system is just awful.  It will automatically downcast
// Note: types in assignment and argument inference, totally breaking the
// Note: type safety of having this subclass.
class OXT extends Token {
  OXT(BigInt value) : super(Tokens.OXT, value);

  static OXT zero = OXT.fromInt(BigInt.zero);

  static OXT fromInt(BigInt keiki) {
    return OXT(keiki);
  }

  static OXT fromDouble(double value) {
    return cast(Tokens.OXT.fromDouble(value));
  }

  static OXT cast(Token token) {
    if (token.type != Tokens.OXT) {
      throw AssertionError('Token type mismatch!: $token');
    }
    return OXT(token.intValue);
  }

  @override
  OXT multiplyInt(int other) {
    return cast(super.multiplyInt(other));
  }

  @override
  OXT multiplyDouble(double other) {
    return cast(super.multiplyDouble(other));
  }

  @override
  OXT operator *(double other) {
    return multiplyDouble(other);
  }

  @override
  OXT divideDouble(double other) {
    return cast(super.divideDouble(other));
  }

  @override
  OXT operator /(double other) {
    return divideDouble(other);
  }

  @override
  OXT subtract(Token other) {
    return cast(super.subtract(other));
  }

  @override
  OXT operator -(Token other) {
    return subtract(other);
  }

  @override
  OXT add(Token other) {
    return cast(super.add(other));
  }

  @override
  OXT operator +(Token other) {
    return add(other);
  }
}

// TODO: Convert to Token
@deprecated
class ETH extends ScalarValue<double> {
  const ETH(double value) : super(value);

  static ETH fromWei(BigInt wei) {
    return ETH(wei / BigInt.from(1e18));
  }

  // TODO: Figure out how to move these operator overloads to the base class
  ETH operator *(double other) {
    return ETH(value * other);
  }

  ETH operator /(double other) {
    return ETH(value / other);
  }

  @override
  String toString() {
    return 'ETH{$value}';
  }
}

@deprecated
class GWEI extends ScalarValue<double> {
  const GWEI(double value) : super(value);

  ETH toEth() {
    return ETH(value / 1e9);
  }

  // TODO: Figure out how to move these operator overloads to the base class
  GWEI operator *(num other) {
    return GWEI(value * other);
  }

  GWEI operator /(double other) {
    return GWEI(value / other);
  }

  static GWEI fromWei(BigInt wei) {
    return GWEI(wei / BigInt.from(1e9));
  }

  @override
  String toString() {
    return 'GWEI{$value}';
  }
}

class USD extends ScalarValue<double> {
  static const zero = USD(0.0);

  // TODO: rebase on pennies?
  const USD(double value) : super(value);

  USD multiplyDouble(double other) {
    return USD(value * other);
  }

  USD operator +(USD other) {
    return USD(value + other.value);
  }

  USD operator -(USD other) {
    return USD(value - other.value);
  }

  USD operator *(double other) {
    return multiplyDouble(other);
  }

  USD divideDouble(double other) {
    return USD(value / other);
  }

  USD operator /(double other) {
    return divideDouble(other);
  }

  String formatCurrency(
      {@required Locale locale,
      int precision = 2,
      bool showPrefix = true,
      showSuffix = false}) {
    return (showPrefix ? '\$' : '') +
        _formatCurrency(this.value, locale: locale, precision: precision) +
        (showSuffix ? ' USD' : '');
  }

  /// convert a token amount and price to string
  static String formatUSDValue({
    BuildContext context,
    Token tokenAmount,
    USD price,
    bool showSuffix = true,
  }) {
    return ((price ?? USD.zero) * (tokenAmount ?? Tokens.TOK.zero).floatValue)
        .formatCurrency(
            locale: context.locale,
            precision: 2,
            showPrefix: false,
            showSuffix: showSuffix);
  }
}

String toFixedLocalized(num value,
    {int precision = 2, String ifNull = "...", @required Locale locale}) {
  return formatCurrency(value,
      locale: locale, ifNull: ifNull, precision: precision);
}

/// Format a currency to default precision with an optional suffix and null behavior.
String formatCurrency(
  num value, {
  String suffix,

  /// The exact number of digits, possibly zero padded, to display after the decimal.
  /// If minPrecision and maxPrecision are specified this value is ignored.
  /// e.g. 1.00, 1.01
  int precision = 2,

  /// If minPrecision and maxPrecision are specified the value shows the required number
  /// of digits after the decimal with a minimum (zero padded) and up to the maximum provided.
  /// e.g. 1.0, 1.123456789
  int maxPrecision,
  int minPrecision,

  /// If true show ellipsis when full precision is not shown
  bool showPrecisionIndicator = false,
  String ifNull = "...",
  @required Locale locale,
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
        NumberFormat(format, locale?.toLanguageTag()).format(value);

    var precisionIndicator = '';
    if (showPrecisionIndicator ?? false) {
      const ellipsis = '…';
      final unrestricted =
          NumberFormat("#0." + "#" * 16, locale?.toLanguageTag()).format(value);
      precisionIndicator =
          restricted.length < unrestricted.length ? ellipsis : '';
    }

    return restricted + precisionIndicator + suffixPadded;
  }
  // fixed precision
  else {
    final format = "#0." + "0" * precision;
    return NumberFormat(format, locale?.toLanguageTag()).format(value) +
        suffixPadded;
  }
}

final _formatCurrency = formatCurrency;
