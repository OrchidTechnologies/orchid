import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:orchid/util/hex.dart';
import 'dart:typed_data';
import 'package:web3dart/crypto.dart';
import '../orchid_crypto.dart';
import 'abi_encode.dart';
import 'package:web3dart/credentials.dart' as web3;

// Orchid Lottery ticket serialization and evaluation.
// This is direct port of the JS version of this class.
// @see ticket_test for validation.
class OrchidTicket {
  final uint64 = BigInt.from(2).pow(64) - BigInt.one;
  final uint128 = BigInt.from(2).pow(128) - BigInt.one;
  final addrtype = (BigInt.from(2).pow(160)) - BigInt.one;

  late BigInt packed0, packed1;
  late String sig_r, sig_s;

  OrchidTicket({
    required BigInt data, // uint256
    required EthereumAddress lotaddr,
    required EthereumAddress token,
    required BigInt amount, // uint128
    required BigInt ratio, // uint64
    required EthereumAddress funder,
    required EthereumAddress recipient,
    required BigInt commitment, // bytes32
    required BigInt privateKey, // uint256
    int? millisecondsSinceEpoch,
  }) {
    this.initTicketData(data, lotaddr, token, amount, ratio, funder, recipient,
        commitment, privateKey,
        millisecondsSinceEpoch: millisecondsSinceEpoch);
  }

  OrchidTicket.fromPacked(
    this.packed0,
    this.packed1,
    this.sig_r,
    this.sig_s,
  );

  OrchidTicket.fromSerialized(String str) {
    final ticket = [];
    for (var i = 0; i < str.length; i += 64) {
      ticket.add(str.substring(i, i + 64));
    }
    this.packed0 = BigInt.parse(ticket[0], radix: 16);
    this.packed1 = BigInt.parse(ticket[1], radix: 16);
    this.sig_r = ticket[2].startsWith("0x") ? ticket[2] : '0x' + ticket[2];
    this.sig_s = ticket[3].startsWith("0x") ? ticket[3] : '0x' + ticket[3];
  }

  void initTicketData(
    BigInt data, // uint256
    EthereumAddress lotaddr,
    EthereumAddress token,
    BigInt amount,
    BigInt ratio,
    EthereumAddress funder,
    EthereumAddress recipient,
    BigInt commitment,
    BigInt privateKey, {
    int? millisecondsSinceEpoch,
  }) {
    DateTime nowUtc;
    if (millisecondsSinceEpoch != null) {
      // print('millisecondsSinceEpoch: $millisecondsSinceEpoch');
      nowUtc = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
          isUtc: true);
    } else {
      nowUtc = DateTime.now().toUtc();
    }
    final dateForNonce =
        '${nowUtc.toIso8601String().replaceFirst('T', ' ').replaceFirst('Z', '')}000';
    Uint8List hash = keccak256(Uint8List.fromList(utf8.encode(dateForNonce)));
    final hashhex = bytesToHex(hash);
    final hashint = BigInt.parse(hashhex, radix: 16);
    final l2nonce = hashint & uint64;
    BigInt expire = BigInt.from(2).pow(31) - BigInt.from(1);
    final issued = BigInt.from(nowUtc.millisecondsSinceEpoch / 1000);
    BigInt packed0 = (issued << 192) | (l2nonce << 128) | amount;
    BigInt packed1 = (expire << 224) |
        (ratio << 160) |
        BigInt.parse(funder.toString().substring(2), radix: 16);

    final encoded = '' +
        AbiEncodePacked.bytes1(0x19) +
        AbiEncodePacked.bytes1(0x00) +
        AbiEncodePacked.address(lotaddr) +
        '64'.padLeft(64, '0') +
        AbiEncodePacked.address(token) +
        AbiEncodePacked.address(recipient) +
        bytesToHex(keccak256(commitment.toBytes32())) +
        AbiEncodePacked.uint256(packed0) +
        AbiEncodePacked.uint256(packed1) +
        AbiEncodePacked.uint256(data);

    final payload = Uint8List.fromList(hex.decode(encoded));
    final credentials =
        web3.EthPrivateKey.fromHex(Crypto.formatSecretFixed(privateKey));
    MsgSignature sig = sign(keccak256(payload), credentials.privateKey);

    packed1 = (packed1 << 1) | BigInt.from((sig.v - 27) & 1);
    this.packed0 = packed0;
    this.packed1 = packed1;
    this.sig_r = AbiEncode.toHexBytes32(sig.r);
    this.sig_s = AbiEncode.toHexBytes32(sig.s);
  }

  String serializeTicket() {
    return AbiEncode.uint256(this.packed0) +
        AbiEncode.uint256(this.packed1) +
        Hex.remove0x(sig_r) +
        Hex.remove0x(sig_s);
  }

  BigInt nonce() {
    return (packed0 >> 128) & uint64;
  }

  bool isWinner(String reveal) {
    final ratio = uint64 & (packed1 >> 161);
    final revealBytes = Hex.parseBigInt(reveal).toBytesUint256();
    final nonceBytes = nonce().toBytesUint128();
    final message = Uint8List.fromList([...revealBytes, ...nonceBytes]);
    final Uint8List digest = keccak256(message);
    final hash = BigInt.parse(bytesToHex(digest), radix: 16);
    final comp = uint64 & hash;
    return ratio >= comp;
  }

  void printTicket() {
    final amount = packed0 & uint128;
    final funder = addrtype & (packed1 >> 1);
    final ratio = uint64 & (packed1 >> 161);

    print('Ticket data:');
    // print(' Data: ${parseInt(this.data, 16)}');
    // print(' Reveal: ${this.commitment}');
    print(' Packed0: ${this.packed0}');
    print(' Packed1: ${this.packed1}');
    print('Packed data:');
    print(' Amount: $amount');
    print(' Nonce: ${nonce()}');
    print(' Funder: $funder');
    print(' Ratio: $ratio');
    print('r: ${this.sig_r}\ns: ${this.sig_s}');
  }
}
