import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import '../orchid_crypto.dart';
import 'chains.dart';
import 'package:orchid/util/format_currency.dart' as units;

// Token type
// Note: Unfortunately Dart does not have a polyomorphic 'this' type so the
// Note: token type cannot serve as a typesafe factory for the token subtypes
// Note: as we (used to) do in the dapp. See token-specific Token subclasses for certain
// Note: tokens such as OXT.
class TokenType {
  final int chainId;
  final String symbol;
  final int decimals;
  final ExchangeRateSource? exchangeRateSource;
  final String iconPath;

  /// The symbol name to be used in the Orchid config for the back-end.
  final String? configSymbolOverride;

  /// The ERC20 contract address if this is a non-native token on its chain.
  final EthereumAddress? erc20Address;

  /// Returns true if this token is the native (gas) token on its chain.
  bool get isNative {
    return erc20Address == null;
  }

  Chain get chain {
    return Chains.chainFor(chainId);
  }

  SvgPicture get icon {
    return SvgPicture.asset(iconPath);
  }

  const TokenType({
    required this.chainId,
    required this.symbol,
    this.configSymbolOverride,
    this.exchangeRateSource,
    this.decimals = 18,
    this.erc20Address,
    required this.iconPath,
  });

  // Return 1eN where N is the decimal count.
  int get multiplier {
    return Math.pow(10, this.decimals).toInt();
  }

  // From the integer denomination value e.g. WEI for ETH
  Token fromInt(BigInt intValue) {
    return Token(this, intValue);
  }

  Token fromIntString(String s) {
    return fromInt(BigInt.parse(s));
  }

  Token get zero {
    return fromInt(BigInt.zero);
  }

  // From a number representing the nominal token denomination, e.g. 1.0 OXT
  Token fromDouble(double val) {
    // Note: No explicit rounding needed here because BigInt converts for us
    // Note: and round() on the double would overflow Dart's native int.
    return fromInt(BigInt.from(val * this.multiplier));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenType &&
          runtimeType == other.runtimeType &&
          chainId == other.chainId &&
          symbol == other.symbol &&
          decimals == other.decimals;

  @override
  int get hashCode => chainId.hashCode ^ symbol.hashCode ^ decimals.hashCode;

  @override
  String toString() {
    return 'TokenType{symbol: $symbol}';
  }
}

class Token {
  TokenType type;
  BigInt intValue;

  Token(this.type,
      this.intValue); // The float value in nominal units (e.g. ETH, OXT)

  double get floatValue {
    return intValue.toDouble() / type.multiplier;
  }

  /// No token symbol
  String toFixedLocalized({
    required Locale locale,
    int precision = 4,
    int? maxPrecision,
    int? minPrecision,
    bool showPrecisionIndicator = false,
  }) {
    return units.formatCurrency(
      floatValue,
      locale: locale,
      minPrecision: minPrecision,
      maxPrecision: maxPrecision,
      showPrecisionIndicator: showPrecisionIndicator,
      precision: precision,
    );
  }

  /// Format as value with the symbol suffixed
  String formatCurrency({
    required Locale locale,
    int precision = 4,
    bool showSuffix = true,
    int? maxPrecision,
    int? minPrecision,
    bool showPrecisionIndicator = false,
  }) {
    return units.formatCurrency(floatValue,
        locale: locale,
        precision: precision,
        minPrecision: minPrecision,
        maxPrecision: maxPrecision,
        showPrecisionIndicator: showPrecisionIndicator,
        suffix: showSuffix ? type.symbol : null);
  }

  Token multiplyInt(int other) {
    return type.fromInt(intValue * BigInt.from(other));
  }

  Token multiplyDouble(double other) {
    return type.fromInt(BigInt.from(intValue.toDouble() * other));
  }

  Token operator *(double other) {
    return multiplyDouble(other);
  }

  Token divideDouble(double other) {
    return type.fromInt(BigInt.from(intValue.toDouble() / other));
  }

  Token operator /(double other) {
    return divideDouble(other);
  }

  Token subtract(Token other) {
    assertSameType(other);
    return type.fromInt(intValue - other.intValue);
  }

  Token operator -() {
    return type.fromInt(-intValue);
  }

  Token operator -(Token other) {
    return subtract(other);
  }

  bool operator <(Token other) {
    return intValue < other.intValue;
  }

  bool operator <=(Token other) {
    return intValue <= other.intValue;
  }

  bool operator >(Token other) {
    return intValue > other.intValue;
  }

  bool operator >=(Token other) {
    return intValue >= other.intValue;
  }

  Token add(Token other) {
    assertSameType(other);
    return type.fromInt(intValue + other.intValue);
  }

  Token operator +(Token other) {
    return add(other);
  }

  bool ltZero() {
    return intValue < BigInt.zero;
  }

  bool gtZero() {
    return intValue > BigInt.zero;
  }

  bool lteZero() {
    return intValue <= BigInt.zero;
  }

  bool isZero() {
    return intValue == BigInt.zero;
  }

  bool isNotZero() {
    return !isZero();
  }

  bool gteZero() {
    return intValue >= BigInt.zero;
  }

  void assertType(TokenType type) {
    if (this.type != type) {
      throw AssertionError('Token $this is not $type');
    }
  }

  void assertSameType(Token other) {
    assertSameTypes(this, other);
  }

  static assertSameTypes(Token a, Token b) {
    if (a.type != b.type) {
      throw AssertionError('Token type mismatch 2!: ${a.type}, ${b.type}');
    }
  }

  // Keeping these here to avoid overloading the math funcs
  static T min<T extends Token>(T a, T b) {
    assertSameTypes(a, b);
    return a.intValue < b.intValue ? a : b;
  }

  // Keeping these here to avoid overloading the math funcs
  static T max<T extends Token>(T a, T b) {
    assertSameTypes(a, b);
    return a.intValue > b.intValue ? a : b;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Token &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          intValue == other.intValue;

  @override
  int get hashCode => type.hashCode ^ intValue.hashCode;

  @override
  String toString() {
    return 'Token{type: ${type.symbol}, floatValue: $floatValue}';
  }
}

