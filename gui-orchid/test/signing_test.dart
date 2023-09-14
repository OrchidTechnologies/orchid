import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/abi_encode.dart';
import 'package:orchid/vpn/purchase/orchid_pac_transaction.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:convert/convert.dart';
//import 'package:orchid/api/orchid_crypto.dart' as orc;

void main() {
  group('signing tests', () {
    //

    /*
    // crypto_keys
    test('sign1', () {
      EcPrivateKey ecPrivateKey = EcPrivateKey(eccPrivateKey: BigInt.from(1234), curve: curves.p256k);

      // Create a signer for the key using the HMAC/SHA-256 algorithm
      var signer = ecPrivateKey.createSigner(algorithms.signing.ecdsa.sha256);

      var content = "It's me, really me";
      var signature = signer.sign("It's me, really me".codeUnits);

      print("Signing '$content'");
      print('Signature: ${signature.data}');
    });
     */

    // web3dart sign transaction
    // Note: The key included in this test is unused and for unit test purposes only.
    /*
    test('sign transaction', () async {
      final credentials = EthPrivateKey.fromHex(
          'a2fd51b96dc55aeb14b30d55a6b3121c7b9c599500c1beb92a389c3377adc86e');
      final transaction = Transaction(
        from: await credentials.extractAddress(),
        to: EthereumAddress.fromHex(
            '0xC914Bb2ba888e3367bcecEb5C2d99DF7C7423706'),
        nonce: 0,
        gasPrice: EtherAmount.inWei(BigInt.one),
        maxGas: 10,
        value: EtherAmount.inWei(BigInt.from(10)),
      );

      final client = Web3Client(null, null);
      final signature =
          await client.signTransaction(credentials, transaction, chainId: 1);

      expect(bytesToHex(signature),
          'f85d80010a94c914bb2ba888e3367bceceb5c2d99df7c74237060a8025a0a78c2f8b0f95c33636b2b1b91d3d23844fba2ec1b2168120ad64b84565b94bcda0365ecaff22197e3f21816cf9d428d695087ad3a8b7f93456cd48311d71402578');
    });
     */

    // web3dart sign string
    // Note: The key included in this test is unused and for unit test purposes only.
    test('sign hash', () async {
      /*
      Using account: 0xCd4a46bc025155dab335566A3ce07D84841548de
      with key 0xc173fc79d5cc36f10e25b6df0bf13937309e0b407fba0ed71a5c710ce24bb25a
      sig = SignedMessage(
        messageHash=HexBytes('0xdf716582eb615a89dc9ea0d3cca4bb7798fdc78843822d75306506a6a212cc90'),
        r=76207269597759931330743205990838990680541603493902835943713539710575931034798,
        s=30500193081265128813579058796870356556478071792939743768276327985656390278791,
        v=28,
        signature=HexBytes('0xa87bc93b30e91796bade4481ce91f11f1965c96c37...'))
       */
      final credentials = EthPrivateKey.fromHex(
          '0xc173fc79d5cc36f10e25b6df0bf13937309e0b407fba0ed71a5c710ce24bb25a');
      var messageHash = /*0x*/ 'df716582eb615a89dc9ea0d3cca4bb7798fdc78843822d75306506a6a212cc90';

      List<int> payload = hex.decode(messageHash);
      print("payload = ${hex.encode(payload)}");
      // Use sign(), not credentials.sign() which does a keccak256 on payload.
      // MsgSignature sig = sign(payload, credentials.privateKey);
      // print("\nr=${sig.r},\ns=${sig.s},\nv=${sig.v}");
    });

    // 'sig': '0xacceaf5934ee993f5b36c319e24b1391dab532b964091ce8496797fcadded22a614cd43390398acb9016571c1d3212299ad7427af78178b6a2d254c8d919a4711b'
    test('sig encoding test', () async {
      var r = BigInt.parse(
          '76207269597759931330743205990838990680541603493902835943713539710575931034798');
      var s = BigInt.parse(
          '30500193081265128813579058796870356556478071792939743768276327985656390278791');
      var v = BigInt.from(28);
      List<int> out1 = Uint8List.fromList(
          Web3DartUtils.padUint8ListTo32(intToBytes(r)) +
              Web3DartUtils.padUint8ListTo32(intToBytes(s)) +
              intToBytes(v));
      // print(out1);
      var out2 = hex.decode(AbiEncode.uint256(r)) +
          hex.decode(AbiEncode.uint256(s)) +
          intToBytes(v);
      // print(out2);
      expect(out1, equals(out2));
      print('0x' + hex.encode(out2));
    });

    /*
    test('encode packed', () async {
      var data = [
        0x19,
        0x00,
        '0x8E79E0D624Dc149cCA9D7785a5d7C03d9fb2E977',
        100,
        0,
        '0x0000000000000000000000000000000000000000',
        1000000000000000000,
        100000000000000000,
        0,
        0,
        1
      ];
      var msg =
          '19008e79e0d624dc149cca9d7785a5d7c03d9fb2e9770000000000000000000000000000000000000000000000000000000000000064000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000de0b6b3a7640000000000000000000000000000000000000000000000000000016345785d8a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001';

      var encoded = '' +
          // ['bytes1', 'bytes1', 'address', 'uint256', 'uint64', 'address',
          AbiEncodePacked.bytes1(data[0]) +
          AbiEncodePacked.bytes1(data[1]) +
          AbiEncodePacked.address(orc.EthereumAddress.from(data[2])) +
          AbiEncodePacked.uint256(BigInt.from(data[3])) +
          AbiEncodePacked.uint64(BigInt.from(data[4])) +
          AbiEncodePacked.address(orc.EthereumAddress.from(data[5])) +
          //  'uint256', 'int256', 'int256', 'uint256', 'uint128']
          AbiEncodePacked.uint256(BigInt.from(data[6])) +
          AbiEncodePacked.int256(BigInt.from(data[7])) +
          AbiEncodePacked.int256(BigInt.from(data[8])) +
          AbiEncodePacked.uint256(BigInt.from(data[9])) +
          AbiEncodePacked.uint128(BigInt.from(data[10]));

      expect(encoded, equals(msg));

      var encoded2 = OrchidPacSeller.packedAbiEncodedEditParams(
        chainId: 100,
        l3Nonce: 0,
        amount: BigInt.from(1000000000000000000),
        adjust: BigInt.from(100000000000000000),
        warn: BigInt.zero,
        retrieve: BigInt.zero,
        refill: BigInt.one,
      );
      expect(encoded2, equals(msg));
    });
     */

    test('test string encoding', () async {
      var ref =
          r'{"txn": "{\"from\":\"0x605345b6169583f93273f0F21595450DBced3EDB\",\"to\":\"0xA614b7c04303814c1Ed20b1CeEB7Cd5394E1511f\",\"gas\":\"0x57c0\",\"gasPrice\":\"0x1C67C44400\",\"value\":\"0x9184e72a\",\"chainId\":100}", "sig": "0xaaf5660622949db92afbb1ef8c3ff1e690d00f2302604fd383d31b79f2ae43b60683c296c844f6655ffc30a30c12db3dfa2fed4ffb344ee18e832179741070461b"}';
      var txnData =
          '{"from":"0x605345b6169583f93273f0F21595450DBced3EDB","to":"0xA614b7c04303814c1Ed20b1CeEB7Cd5394E1511f","gas":"0x57c0","gasPrice":"0x1C67C44400","value":"0x9184e72a","chainId":100}';
      var txnJson = jsonDecode(txnData);

      var outJson = {
        "txn": PacSubmitSellerTransaction.encodePacTransactionString(txnJson),
        "sig":
            "0xaaf5660622949db92afbb1ef8c3ff1e690d00f2302604fd383d31b79f2ae43b60683c296c844f6655ffc30a30c12db3dfa2fed4ffb344ee18e832179741070461b",
      };
      print(ref);
      print(jsonEncode(outJson));
      expect(jsonDecode(ref), equals(outJson));
      expect(jsonDecode(ref)['txn'], equals(outJson['txn']));
    });

    //
  });
}
