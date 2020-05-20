import 'dart:math' as math;
import 'package:intl/intl.dart';

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

class OXT extends ScalarValue<double> {
  const OXT(double value) : super(value);

  OXT operator *(double other) {
    return OXT(value * other);
  }

  OXT operator /(double other) {
    return OXT(value / other);
  }

  OXT operator -(OXT other) {
    return OXT(value - other.value);
  }

  OXT operator +(OXT other) {
    return OXT(value + other.value);
  }

//  static String format(num value, {int digits = 4}) {
//    return formatCurrency(value, digits: digits, suffix: " OXT");
//  }

  static OXT min(OXT a, OXT b) {
    return OXT(math.min(a.value, b.value));
  }

  static OXT fromWei(BigInt oxtWei) {
    return OXT(oxtWei / BigInt.from(1e18));
  }
}

class ETH extends ScalarValue<double> {
  const ETH(double value) : super(value);

  static ETH fromWei(BigInt wei) {
    return ETH(wei / BigInt.from(1e18));
  }

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

class GWEI extends ScalarValue<double> {
  const GWEI(double value) : super(value);

  ETH toETH() {
    return ETH(value / 1e9);
  }

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
  const USD(double value) : super(value);
}

class Months extends ScalarValue<int> {
  const Months(int value) : super(value);
}

/// Format a currency to default two digits of precision with an optional suffix
/// and null behavior.
String formatCurrency(num value,
    {String suffix, int digits = 2, String ifNull = "..."}) {
  if (value == null) {
    return ifNull;
  }
  return NumberFormat("#0.0" + "#" * (digits - 1)).format(value) +
      (suffix != null ? " $suffix" : "");
}
