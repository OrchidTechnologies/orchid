import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_eth/v0/orchid_contract_v0.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import '../orchid_crypto.dart';
import 'chains.dart';

class TokenTypes {
  // Indicates that we do not have a source for pricing information for the token.
  static const ExchangeRateSource NoExchangeRateSource = null;

  // Override the symbol to ETH so that ETH-equivalent tokens care share this.
  static const ETHExchangeRateSource = BinanceExchangeRateSource(symbolOverride: 'ETH');
  static const TokenType ETH = TokenType(
    symbol: 'ETH',
    exchangeRateSource: ETHExchangeRateSource,
    chainId: Chains.ETH_CHAINID,
  );

  static TokenType OXT = TokenType(
    symbol: 'OXT',
    exchangeRateSource: BinanceExchangeRateSource(),
    chainId: Chains.ETH_CHAINID,
    erc20Address: OrchidContractV0.oxtContractAddress,
  );

  static const TokenType XDAI = TokenType(
      symbol: 'xDAI',
      // Binance lists DAIUSDT but the value is bogus. The real pair is USDTDAI, so invert.
      exchangeRateSource: BinanceExchangeRateSource(symbolOverride: 'DAI', inverted: true),
      chainId: Chains.XDAI_CHAINID);

  static const TokenType TOK = TokenType(
      symbol: 'TOK',
      exchangeRateSource: ETHExchangeRateSource,
      chainId: Chains.GANACHE_TEST_CHAINID);

  static const TokenType AVAX = TokenType(
      symbol: 'AVAX',
      exchangeRateSource: BinanceExchangeRateSource(),
      chainId: Chains.AVALANCHE_CHAINID);

  static const TokenType BNB = TokenType(
      symbol: 'BNB',
      exchangeRateSource: BinanceExchangeRateSource(),
      chainId: Chains.BSC_CHAINID);

  static const TokenType MATIC = TokenType(
      symbol: 'MATIC',
      exchangeRateSource: BinanceExchangeRateSource(),
      chainId: Chains.POLYGON_CHAINID);

  static const TokenType OETH = TokenType(
      symbol: 'ETH',
      // OETH is ETH on L2
      exchangeRateSource: ETHExchangeRateSource,
      chainId: Chains.OPTIMISM_CHAINID);

  // Aurora is an L2 on Near
  static const TokenType AURORA_ETH = TokenType(
      symbol: 'ETH',
      // aETH should ultimately track the price of ETH
      exchangeRateSource: ETHExchangeRateSource,
      chainId: Chains.AURORA_CHAINID);

  static const TokenType ARBITRUM_ETH = TokenType(
    symbol: 'ETH',
    // AETH is ETH on L2
    exchangeRateSource: ETHExchangeRateSource,
    chainId: Chains.ARBITRUM_ONE_CHAINID,
  );

  static const TokenType FTM = TokenType(
    symbol: 'FTM',
    exchangeRateSource: BinanceExchangeRateSource(),
    chainId: Chains.FANTOM_CHAINID,
  );

  static const TokenType TLOS = TokenType(
    symbol: 'TLOS',
    exchangeRateSource: NoExchangeRateSource,
    chainId: Chains.TELOS_CHAINID,
  );

  static const TokenType RBTC = TokenType(
    symbol: 'RTBC',
    exchangeRateSource: BinanceExchangeRateSource(symbolOverride: 'BTC'),
    chainId: Chains.RSK_CHAINID,
  );
}

// Token type
// Note: Unfortunately Dart does not have a polyomorphic 'this' type so the
// Note: token type cannot serve as a typesafe factory for the token subtypes
// Note: as we (used to) do in the dapp. See token-specific Token subclasses for certain
// Note: tokens such as OXT.
class TokenType {
  final int chainId;
  final String symbol;
  final int decimals;
  final ExchangeRateSource exchangeRateSource;

  /// The ERC20 contract address if this is a non-native token on its chain.
  final EthereumAddress erc20Address;

  /// Returns true if this token is the native (gas) token on its chain.
  bool get isNative {
    return erc20Address == null;
  }

  Chain get chain {
    return Chains.chainFor(chainId);
  }

  const TokenType({
    @required this.chainId,
    @required this.symbol,
    this.exchangeRateSource,
    this.decimals = 18,
    this.erc20Address,
  });

  // Return 1eN where N is the decimal count.
  int get multiplier {
    return Math.pow(10, this.decimals);
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
  int get hashCode =>
      chainId.hashCode ^ symbol.hashCode ^ decimals.hashCode;

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
      throw AssertionError('Token ${this} is not ${type}');
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
