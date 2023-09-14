import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';

// Support migration of legacy code and clarify explicit usage of OXT.
// TODO: Convert to Token
@deprecated
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

// Support migration of legacy code and clarify explicit usage of OXT.
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

