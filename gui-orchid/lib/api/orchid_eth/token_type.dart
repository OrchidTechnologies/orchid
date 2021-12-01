import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'chains.dart';

class TokenTypes {
  static const TokenType ETH = TokenType(
    name: 'ETH',
    symbol: 'ETH',
    exchangeRateSource: BinanceExchangeRateSource(),
    decimals: 18,
    chainId: Chains.ETH_CHAINID,
  );

  // See class OXT.
  static const TokenType OXT = TokenType(
    name: 'OXT',
    symbol: 'OXT',
    exchangeRateSource: BinanceExchangeRateSource(),
    decimals: 18,
    chainId: Chains.ETH_CHAINID,
  );

  static const TokenType XDAI = TokenType(
      name: 'xDAI',
      symbol: 'xDAI',
      exchangeRateSource:
          BinanceExchangeRateSource(symbolOverride: 'DAI', inverted: true),
      decimals: 18,
      chainId: Chains.XDAI_CHAINID);

  static const TokenType TOK = TokenType(
      name: 'TOK',
      symbol: 'TOK',
      exchangeRateSource:
          BinanceExchangeRateSource(symbolOverride: 'ETH', inverted: true),
      decimals: 18,
      chainId: Chains.GANACHE_TEST_CHAINID);

  static const TokenType AVAX = TokenType(
      name: 'Avalanche',
      symbol: 'AVAX',
      exchangeRateSource:
      BinanceExchangeRateSource(),
      decimals: 18,
      chainId: Chains.AVALANCHE_CHAINID);

  static const TokenType BNB = TokenType(
      name: 'BNB',
      symbol: 'BNB',
      exchangeRateSource:
      BinanceExchangeRateSource(),
      decimals: 18,
      chainId: Chains.BSC_CHAINID);

  static const TokenType MATIC = TokenType(
      name: 'MATIC',
      symbol: 'MATIC',
      exchangeRateSource:
      BinanceExchangeRateSource(),
      decimals: 18,
      chainId: Chains.POLYGON_CHAINID);

  /*
  static const TokenType AETH = TokenType(
    name: 'AETH',
    symbol: 'AETH',
    exchangeRateSource: BinanceExchangeRateSource(),
    decimals: 18,
    chainId: Chains.ARBITRUM_ONE_CHAINID,
  );
   */

}

// ERC20 Token type
// Note: Unfortunately Dart does not have a polyomorphic 'this' type so the
// Note: token type cannot serve as a typesafe factory for the token subtypes
// Note: as we (used to) do in the dapp. See token-specific Token subclasses for certain
// Note: tokens such as OXT.
class TokenType {
  final int chainId;
  final String name;
  final String symbol;
  final int decimals;
  final ExchangeRateSource exchangeRateSource;

  Chain get chain {
    return Chains.chainFor(chainId);
  }

  const TokenType({
    @required this.chainId,
    @required this.name,
    @required this.symbol,
    @required this.decimals,
    @required this.exchangeRateSource,
  });

  // Return 1eN where N is the decimal count.
  int get multiplier {
    return Math.pow(10, this.decimals);
  }

  // From the integer denomination value e.g. WEI for ETH
  Token fromInt(BigInt intValue) {
    return Token(this, intValue);
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
          name == other.name &&
          symbol == other.symbol &&
          decimals == other.decimals;

  @override
  int get hashCode =>
      chainId.hashCode ^ name.hashCode ^ symbol.hashCode ^ decimals.hashCode;

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

  String toFixedLocalized({int digits = 4}) {
    return floatValue.toStringAsFixed(digits);
  }

  // Format as currency with the symbol suffixed
  String formatCurrency({int digits = 4}) {
    return this.toFixedLocalized(digits: digits) + " ${type.symbol}";
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
    assertType(other);
    return type.fromInt(intValue - other.intValue);
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
    assertType(other);
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

  bool gteZero() {
    return intValue >= BigInt.zero;
  }

  assertType(Token other) {
    assertSameType(this, other);
  }

  static assertSameType(Token a, Token b) {
    if (a.type != b.type) {
      throw AssertionError('Token type mismatch!: ${a.type}, ${b.type}');
    }
  }

  // Keeping these here to avoid overloading the math funcs
  static T min<T extends Token>(T a, T b) {
    assertSameType(a, b);
    return a.intValue < b.intValue ? a : b;
  }

  // Keeping these here to avoid overloading the math funcs
  static T max<T extends Token>(T a, T b) {
    assertSameType(a, b);
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
