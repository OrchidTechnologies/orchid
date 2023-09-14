import 'package:orchid/api/orchid_log.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:orchid/util/hex.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/keccak.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/ec_key_generator.dart';
import 'package:uuid/uuid.dart';
import 'package:uuid/uuid_util.dart';
import 'package:web3dart/credentials.dart' as web3;
import 'package:web3dart/crypto.dart';

import 'orchid_keys.dart';
export 'orchid_keys.dart';

class Crypto {
  static final ECDomainParameters curve = ECCurve_secp256k1();

  /// Generate an Ethereum KeyPair and corresponding address.
  static EthereumKeyPair generateKeyPair() {
    // Generate a keypair using Dart's secure random source.
    final generator = ECKeyGenerator();
    final params = ECKeyGeneratorParameters(curve);
    generator.init(ParametersWithRandom(params, DartSecureRandom()));
    final key = generator.generateKeyPair();
    final BigInt? privateKey = (key.privateKey as ECPrivateKey).d;
    if (privateKey == null) {
      throw Exception('Failed to produce private key');
    }
    return fromPrivateKey(privateKey);
  }

  static EthereumKeyPair fromPrivateKey(BigInt privateKey) {
    final ECDomainParameters curve = ECCurve_secp256k1();

    // Forcing this non-nullable: ECPoint multiply operator appears to produce nulls
    // because it accepts a nullable BigInt.
    final ECPoint publicKeyPoint =
        (curve.G * privateKey)!; // EC scalar multiply

    // X9.62 encoded uncompressed ECPoint is just the prefix value '4' followed by x, y.
    final encoded = publicKeyPoint.getEncoded(false).buffer;
    // Remove the prefix byte
    final publicKey = Uint8List.view(encoded, 1);

    // Derive the Ethereum address from the public key
    final keccakDigest = KeccakDigest(256 /*bits*/);
    final hashed = keccakDigest.process(publicKey);
    final ethereumAddress = Uint8List.view(
        hashed.buffer, 32 /*bytes*/ - 20 /*eth address length bytes*/);

    return new EthereumKeyPair(
        private: privateKey,
        public: toHex(publicKey),
        addressString: toHex(ethereumAddress));
  }

  static String toHex(Uint8List bytes) {
    var result = new StringBuffer('0x');
    bytes.forEach((val) {
      var pad = val < 16 ? '0' : '';
      result.write('$pad${val.toRadixString(16)}');
    });
    return result.toString();
  }

  /// Parse the string with an optional 0x prefix and return the BigInt or
  /// throw an exception if invalid.
  static BigInt parseEthereumPrivateKey(String text) {
    try {
      if (text.toLowerCase().startsWith('0x')) {
        text = text.substring(2);
      }
      var keyInt = BigInt.parse(text, radix: 16);
      if (keyInt > BigInt.from(0) &&
          keyInt < ((BigInt.one << 256) - BigInt.one)) {
        return keyInt;
      } else {
        throw Exception("invalid range");
      }
    } catch (err) {
      throw Exception("invalid key");
    }
  }

  static String uuid() {
    return Uuid(options: {'grng': UuidUtil.cryptoRNG}).v4();
  }
}

class EthereumKeyPair {
  // The EC private key
  final BigInt private;

  // The EC public key
  final String public;

  // TODO: Deprecated, migrate this to EthereumAddress
  // The ethereum address for this keypair
  final String addressString;

  EthereumAddress get address {
    return EthereumAddress.from(addressString);
  }

  const EthereumKeyPair(
      {required this.private,
      required this.public,
      required this.addressString});
}

class DartSecureRandom implements SecureRandom {
  final Random random;

  DartSecureRandom()
      :
        // Dart's cryptographic random number source
        this.random = Random.secure();

  @override
  String get algorithmName => 'dart';

  @override
  int nextUint8() => random.nextInt(1 << 8);

  @override
  int nextUint16() => random.nextInt(1 << 16);

  @override
  int nextUint32() {
    // Simon Binder (simolus3/web3dart)
    // We can't write 1 << 32 because that evaluates to 0 on js
    return random.nextInt(4294967296);
  }

  // Inspired by code from Simon Binder (simolus3/web3dart)
  @override
  BigInt nextBigInteger(int bitLength) {
    final byteLength = bitLength ~/ 8;
    final remainderBits = bitLength % 8;
    final part1 = bytesToUnsignedInt(nextBytes(byteLength));
    final part2 = BigInt.from(random.nextInt(1 << remainderBits));
    return part1 + (part2 << (byteLength * 8));
  }

  @override
  Uint8List nextBytes(int count) {
    var bytes = List<int>.generate(count, (_) => nextUint8());
    return Uint8List.fromList(bytes);
  }

  @override
  void seed(CipherParameters params) {
    throw Exception("Dart secure random is already seeded.");
  }
}

class EthereumAddress {
  // Used as null value in contract calls.
  static EthereumAddress zero =
      EthereumAddress.from('0x0000000000000000000000000000000000000000');

  final BigInt value;

  EthereumAddress(BigInt value)
      :
        // Allow the string parser to validate.
        this.value =
            parse(value.toRadixString(16).toLowerCase().padLeft(40, '0'));

  EthereumAddress.from(String text) : this.value = parse(text);

  static fromNullable(String? text) {
    if (text == 'null') { return null; }
    return text == null ? null : EthereumAddress.from(text);
  }

  // Display the optionally prefixed 40 char hex address.
  // If 'elide' is true show only the first and last four characters.
  @override
  String toString({bool prefix = true, bool elide = false}) {
    final raw = value.toRadixString(16).padLeft(40, '0');
    final eip55 = Web3DartUtils.eip55ChecksumEthereumAddress(raw);
    final hex = prefix ? eip55 : Hex.remove0x(eip55);
    if (elide)
      return elideAddressString(hex);
    else
      return hex;
  }

  static String elideAddressString(String hex) {
    final prefix = hex.startsWith('0x');
    return hex.substring(0, prefix ? 6 : 4) +
        '…' +
        hex.substring(hex.length - 4, hex.length);
  }

  static bool isValid(String text) {
    try {
      EthereumAddress.parse(text);
      return true;
    } catch (err) {
      return false;
    }
  }

  static BigInt parse(String? text) {
    if (text == null) {
      throw Exception("invalid, null");
    }
    text = Hex.remove0x(text);
    if (text.length != 40) {
      throw Exception("invalid, length: $text, ${text.length}");
    }
    // eip55 check
    if (!Web3DartUtils.isEip55ValidEthereumAddress(text)) {
      throw Exception("invalid eth address: $text");
    }
    try {
      var val = BigInt.parse(text, radix: 16);
      if (val < BigInt.from(0)) {
        throw Exception("invalid, range");
      }
      return val;
    } catch (err) {
      print(err);
      throw Exception("invalid, value");
    }
  }

  @override
  bool operator ==(other) {
    return other is EthereumAddress && value == other.value;
  }

  @override
  // TODO: implement hashCode
  int get hashCode => value.hashCode;
}

class Web3DartUtils {
  /// Converts an Ethereum address to a checksummed address (EIP-55).
  static String eip55ChecksumEthereumAddress(String address) {
    return web3.EthereumAddress.fromHex(address).hexEip55;
  }

  /// Returns true if the eth address is valid and conforms to the rules of EIP55.
  static bool isEip55ValidEthereumAddress(String address) {
    try {
      web3.EthereumAddress.fromHex(address);
      // web3.EthereumAddress.fromHex(address, enforceEip55: false);
      // _fromHex(address);
    } catch (err) {
      log("XXX: isEip55ValidEthereumAddress err = $err");
      return false;
    }
    return true;
  }

  static MsgSignature web3Sign(Uint8List payload, StoredEthereumKey key) {
    final credentials = web3.EthPrivateKey.fromHex(key.formatSecretFixed());
    //print("payload = ${hex.encode(payload)}");
    // Use web3 sign(), not web3 credentials.sign() which does a keccak256 on payload.
    return sign(payload, credentials.privateKey);
  }

  // Imitating what web3dart does
  static Uint8List padUint8ListTo32(Uint8List data) {
    return data.length == 32 ? data : Uint8List(32)
      ..setRange(32 - data.length, 32, data);
  }
}
