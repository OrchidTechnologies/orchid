
import '../orchid_crypto.dart';

class AbiEncode {
  // Pad a 40 character address to 64 characters with no prefix
  static String address(EthereumAddress address, {prefix: false}) {
    return (prefix ? '0x' : '') +
        address.toString(prefix: false).toLowerCase().padLeft(64, '0');
  }

  static String uint256(BigInt value) {
    return value.toRadixString(16).padLeft(64, '0');
  }

  static String uint256From(BigInt hi, BigInt low) {
    var value = (hi << 128) + low;
    return uint256(value);
  }
}
