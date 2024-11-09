import 'dart:typed_data';

import '../orchid_crypto.dart';
import 'package:orchid/util/strings.dart';

class AbiEncode {
  // Pad a 40 character address to 64 characters with no prefix
  static String address(EthereumAddress address, {prefix = false}) {
    return (prefix ? '0x' : '') +
        address.toString(prefix: false).toLowerCase().padLeft(64, '0');
  }

  static String uint256(BigInt value) {
    return value.toUnsigned(256).toRadixString(16).padLeft(64, '0');
  }

  static String int256(BigInt value) {
    return value.toRadixString(16).padLeft(64, '0');
  }

  static String toHexBytes32(BigInt val) {
    return '0x' + int256(val);
  }

  static String uint128(BigInt value) {
    return value.toUnsigned(128).toRadixString(16).padLeft(64, '0');
  }

  static String uint80(BigInt value) {
    return value.toUnsigned(80).toRadixString(16).padLeft(64, '0');
  }

  static String uint64(BigInt value) {
    return value.toUnsigned(64).toRadixString(16).padLeft(64, '0');
  }

  static String uint8(int value) {
    return value.toUnsigned(8).toRadixString(16).padLeft(64, '0');
  }

  static String uint256From(BigInt hi, BigInt low) {
    var value = (hi << 128) + low;
    return uint256(value);
  }

  static String bytes32(BigInt value) {
    return value.toRadixString(16).padLeft(64, '0');
  }
}

class AbiEncodePacked {
  // Pad a 40 character address to 64 characters with no prefix
  static String address(EthereumAddress address, {prefix = false}) {
    return (prefix ? '0x' : '') +
        address.toString(prefix: false).toLowerCase().padLeft(20, '0');
  }

  static String uint256(BigInt value) {
    return value.toUnsigned(256).toRadixString(16).suffix(64).padLeft(64, '0');
  }

  static String uint128(BigInt value) {
    return value.toUnsigned(128).toRadixString(16).suffix(32).padLeft(32, '0');
  }

  static String uint64(BigInt value) {
    return value.toUnsigned(64).toRadixString(16).suffix(16).padLeft(16, '0');
  }

  static String int256(BigInt value) {
    return value.toRadixString(16).suffix(64).padLeft(64, '0');
  }

  static String bytes1(int value) {
    return (value & 0xff).toRadixString(16).padLeft(2, '0');
  }
}

// Add some extension methods to BigInt
extension BigIntExtension on BigInt {
  Uint8List toBytes32() {
    return toBytesUint256();
  }

  Uint8List toBytesUint256() {
    final number = this;
    // Assert the number is non-negative and fits within 256 bits
    assert(number >= BigInt.zero && number < (BigInt.one << 256),
        'Number must be non-negative and less than 2^256');
    var byteData = number.toRadixString(16).padLeft(64, '0'); // Ensure 32 bytes
    var result = Uint8List(32);
    for (int i = 0; i < byteData.length; i += 2) {
      var byteString = byteData.substring(i, i + 2);
      var byteValue = int.parse(byteString, radix: 16);
      result[i ~/ 2] = byteValue;
    }
    return result;
  }

  Uint8List toBytesUint128() {
    final number = this;
    // Assert the number is non-negative and fits within 128 bits
    assert(number >= BigInt.zero && number < (BigInt.one << 128),
        'Number must be non-negative and less than 2^128');
    var byteData = number.toRadixString(16).padLeft(32, '0'); // Ensure 16 bytes
    var result = Uint8List(16);
    for (int i = 0; i < byteData.length; i += 2) {
      var byteString = byteData.substring(i, i + 2);
      var byteValue = int.parse(byteString, radix: 16);
      result[i ~/ 2] = byteValue;
    }
    return result;
  }

  Uint8List toBytesUint160() {
    final number = this;
    // Assert the number is non-negative and fits within 160 bits
    assert(number >= BigInt.zero && number < (BigInt.one << 160),
        'Number must be non-negative and less than 2^160');
    var byteData = number.toRadixString(16).padLeft(40, '0'); // Ensure 20 bytes
    var result = Uint8List(20);
    for (int i = 0; i < byteData.length; i += 2) {
      var byteString = byteData.substring(i, i + 2);
      var byteValue = int.parse(byteString, radix: 16);
      result[i ~/ 2] = byteValue;
    }
    return result;
  }

  // For a BigInt representing an Ethereum Address (20 bytes)
  Uint8List toAddress() {
    return toBytesUint160();
  }
}

Uint8List tie(Uint8List a, Uint8List b) {
  return Uint8List.fromList(a + b);
}
