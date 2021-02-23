import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg.dart';
import 'v0/orchid_eth_v0.dart';

class Chains {
  // ignore: non_constant_identifier_names
  static const int ETH_CHAINID = 1;

  // ignore: non_constant_identifier_names
  static Chain Ethereum = Chain(
      chainId: ETH_CHAINID,
      name: "Ethereum",
      nativeCurrency: TokenTypes.ETH,
      providerUrl: OrchidEthereumV0.defaultEthereumProviderUrl,
      icon: SvgPicture.asset('assets/svg/ethereum.svg'));

  // ignore: non_constant_identifier_names
  static const int XDAI_CHAINID = 100;
  static Chain xDAI = Chain(
      chainId: XDAI_CHAINID,
      name: "xDAI",
      nativeCurrency: TokenTypes.XDAI,
      providerUrl: 'https://dai.poa.network',
      icon: SvgPicture.asset('assets/svg/logo-xdai.svg'));

  // TODO: Embed the chain.info db here as we do in the dapp.
  // Get the chain for chainId
  static Chain chainFor(int chainId) {
    switch (chainId) {
      case ETH_CHAINID:
        return Ethereum;
      case XDAI_CHAINID:
        return xDAI;
    }
  }
}

class Chain {
  final int chainId;
  final String name;
  final TokenType nativeCurrency;
  final String providerUrl;

  // Optional icon svg
  final SvgPicture icon;

  const Chain({
    @required this.chainId,
    @required this.name,
    @required this.nativeCurrency,
    @required this.providerUrl,
    this.icon,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Chain &&
          runtimeType == other.runtimeType &&
          chainId == other.chainId;

  @override
  int get hashCode => chainId.hashCode;
}

class TokenTypes {
  // ignore: non_constant_identifier_names
  static const TokenType ETH = TokenType(
      name: 'ETH', symbol: 'ETH', decimals: 18, chainId: Chains.ETH_CHAINID);

  // ignore: non_constant_identifier_names
  // See class OXT.
  static const TokenType OXT = TokenType(
      name: 'OXT', symbol: 'OXT', decimals: 18, chainId: Chains.ETH_CHAINID);

  // ignore: non_constant_identifier_names
  static const TokenType XDAI = TokenType(
      name: 'xDAI',
      symbol: 'xDAI',
      orchidConfigSymbol: 'DAI',
      decimals: 18,
      chainId: Chains.XDAI_CHAINID);
}

// ERC20 Token type
// Note: Unfortunately Dart does not have a polyomorphic 'this' type so the
// Note: token type cannot serve as a typesafe factory for the token subtypes
// Note: as we do in the dapp. See token-specific Token subclasses for certain
// Note: tokens such as OXT.
class TokenType {
  final int chainId;

  Chain get chain {
    return Chains.chainFor(chainId);
  }

  final String name;
  final String symbol;
  final String orchidConfigSymbol; // optional override
  final int decimals;

  const TokenType({
    @required this.chainId,
    @required this.name,
    @required this.symbol,
    this.orchidConfigSymbol,
    @required this.decimals,
  });

  // Return 1eN where N is the decimal count.
  int get multiplier {
    return Math.pow(10, this.decimals);
  }

  // From the integer denomination value e.g. WEI for ETH
  Token fromInt(BigInt intValue) {
    return Token(this, intValue);
  }

  // From a number representing the nominal token denomination, e.g. 1.0 OXT
  Token fromDouble(double val) {
    return fromInt(BigInt.from((val * this.multiplier).round()));
  }

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

  bool lteZero() {
    return intValue <= BigInt.zero;
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
  String toString() {
    return 'Token{type: ${type.symbol}, floatValue: $floatValue}';
  }
}
