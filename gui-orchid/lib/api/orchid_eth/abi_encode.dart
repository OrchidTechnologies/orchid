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
