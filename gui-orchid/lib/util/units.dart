import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';

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

  OXT(BigInt value) : super(TokenTypes.OXT, value);

  static OXT fromInt(BigInt keiki) {
    return OXT(keiki);
  }

  static OXT fromDouble(double value) {
    return cast(TokenTypes.OXT.fromDouble(value));
  }

  static OXT cast(Token token) {
    if (token.type != TokenTypes.OXT) {
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

// TODO: Convert to int pennies?
class USD extends ScalarValue<double> {
  const USD(double value) : super(value);
}

class Months extends ScalarValue<int> {
  const Months(int value) : super(value);
}

/// Format a currency to default two digits of precision with an optional suffix
/// and null behavior.
String formatCurrency(num value,
    {String suffix, int digits = 2, String ifNull = "...", String locale}) {
  if (value == null) {
    return ifNull;
  }
  return NumberFormat("#0.00" + "#" * (digits - 1), locale).format(value) +
      (suffix != null ? " $suffix" : "");
}
