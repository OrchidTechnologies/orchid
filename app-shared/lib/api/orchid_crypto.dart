import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha3.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:pointycastle/key_generators/api.dart';
import 'package:pointycastle/key_generators/ec_key_generator.dart';
import 'package:pointycastle/src/utils.dart' as decode;

class Crypto {
  /// Generate an Ethereum KeyPair and corresponding address.
  static EthereumKeyPair generateEthereumKeyPair() {
    final ECDomainParameters curve = ECCurve_secp256k1();

    // Generate a private key using Dart's secure random source.
    final generator = ECKeyGenerator();
    final params = ECKeyGeneratorParameters(curve);
    generator.init(ParametersWithRandom(params, DartSecureRandom()));
    final key = generator.generateKeyPair();
    final BigInt privateKey = (key.privateKey as ECPrivateKey).d;

    // Derive the public key from the private key
    final ECPoint publicKeyPoint = curve.G * privateKey; // EC scalar multiply
    // X9.62 encoded uncompressed ECPoint is just the prefix value '4' followed by x, y.
    final encoded = publicKeyPoint.getEncoded(false).buffer;
    // Remove the prefix byte
    final publicKey = Uint8List.view(encoded, 1);

    // Derive the Ethereum address from the public key
    final SHA3Digest sha3digest = SHA3Digest(256 /*bits*/);
    final hashed = sha3digest.process(publicKey);
    final ethereumAddress = Uint8List.view(
        hashed.buffer, 32 /*bytes*/ - 20 /*eth address length bytes*/);

    return new EthereumKeyPair(
        private: privateKey,
        public: toHex(publicKey),
        address: toHex(ethereumAddress));
  }

  static String toHex(Uint8List bytes) {
    var result = new StringBuffer('0x');
    bytes.forEach((val) {
      var pad = val < 16 ? '0' : '';
      result.write('$pad${val.toRadixString(16)}');
    });
    return result.toString();
  }
}

class EthereumKeyPair {
  // The EC private key
  final BigInt private;

  // The EC public key
  final String public;

  // The ethereum address for this keypair
  final String address;

  const EthereumKeyPair({this.private, this.public, this.address});
}

class DartSecureRandom implements SecureRandom {
  Random random;

  DartSecureRandom() {
    // Dart's cryptographic random number source
    this.random = Random.secure();
  }

  @override
  int nextUint8() => random.nextInt(1 << 8);

  @override
  int nextUint16() => random.nextInt(1 << 16);

  @override
  int nextUint32() => random.nextInt(1 << 32);

  @override
  String get algorithmName => 'dart';

  // Inspired by code from Simon Binder (simolus3/web3dart)
  @override
  BigInt nextBigInteger(int bitLength) {
    final byteLength = bitLength ~/ 8;
    final remainderBits = bitLength % 8;
    final part1 = decode.decodeBigInt(nextBytes(byteLength));
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
