import 'package:flutter_test/flutter_test.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_ticket.dart';

void main() {
  group('ticket tests', () {
    /*
      JS version output:
      Ticket data:
      Data: NaN
      Reveal: undefined
      Packed0: 0
      Packed1: 74418616462743697996404837125958524653305997647975479859375788807275769590323
      r: 0x0000000065d6bdd66f8fcd69afdfec200000000000000000016345785d8a0000   s: 0xffffffffccccccccccccd000e04d6ec797cfa9ce4093d4cfd1264c8654a1df09
    Packed data:
      Amount: 0
      Nonce: 0
      Funder: 840389638478969449152772927472898064667089090841
      Ratio: 10077190556129977236
     */
    test('Test serialization', () async {
      print("Test serialization round trip");
      final ser1 =
          '0000000000000000000000000000000000000000000000000000000000000000'
          'a48771bb17b2bed6d018c7292668bfda9baa2ccc048b99752fdb684789d97233'
          '0000000065d6bdd66f8fcd69afdfec200000000000000000016345785d8a0000'
          'ffffffffccccccccccccd000e04d6ec797cfa9ce4093d4cfd1264c8654a1df09';
      // Two extra fields in this serialized version?
      // The JS lib ignores these as does our impl.
      // '7b50455687184c0a1f5ff0be3b4b802a3b2a15205a94d33655b1a7529967c9c9'
      // '75f7ee1ed8af30f42902eee69e91c6ca7a936942db9878f34442b187203c2cbb';
      final ticket = OrchidTicket.fromSerialized(ser1);
      // ticket.printTicket();
      expect(ticket.packed0, BigInt.zero);
      expect(ticket.packed1.toString(),
          '74418616462743697996404837125958524653305997647975479859375788807275769590323');
      final ser2 = ticket.serializeTicket();
      expect(ser2, ser1);
    });

    /*
    JS output:
      Ticket data:
      Packed0: 10725299090569305319344573190133412787358038370907851216529272602624
      Packed1: 115792089210356248756420345214244490354657239511130867306431705402380410144357
    Packed data:
      Amount: 2000000000000000000
      Nonce: 10444928296939929927
      Funder: 111798794203442759563723844757346937785445376818
      Ratio: 9223372036854775808
      r: 0xd73c001751ebd66407ef8cb61ffc2a77757d2da4e7ea853af744d1123e68fb4a
      s: 0x03cc65f3e60f1b007609f69f464a1ec2ae10b39805116434f8c647d63c1e7bb6
   */
    test('Test construction', () async {
      print("Test construction");
      final funder =
          EthereumAddress.from('0x13953B378987A76c65F7041BE8CE983381d5E332');
      final signer_key = BigInt.parse(
          '0x1cf5423866f216ecc2ed50c79447249604d274099e1f8e106dde3a5a6eaea365');
      final recipient =
          EthereumAddress.from('0x405BC10E04e3f487E9925ad5815E4406D78B769e');
      final amountf = 1.0;
      final amount = BigInt.from(2000000000000000000) * BigInt.from(amountf);
      final data = BigInt.zero;
      final lotaddr =
          EthereumAddress.from('0x6dB8381b2B41b74E17F5D4eB82E8d5b04ddA0a82');
      final token = EthereumAddress.zero;
      final ratio = BigInt.parse('9223372036854775808');
      final commit = BigInt.parse('0x100');
      final ticket = OrchidTicket(
        data: data,
        lotaddr: lotaddr,
        token: token,
        amount: amount,
        ratio: ratio,
        funder: funder,
        recipient: recipient,
        commitment: commit,
        privateKey: signer_key,
        millisecondsSinceEpoch: 1708638722494,
      );
      // ticket.printTicket();
      expect(ticket.packed0.toString(),
          '10725299090569305319344573190133412787358038370907851216529272602624');
      expect(ticket.packed1.toString(),
          '115792089210356248756420345214244490354657239511130867306431705402380410144357');
      expect(ticket.sig_r,
          '0xd73c001751ebd66407ef8cb61ffc2a77757d2da4e7ea853af744d1123e68fb4a');
      expect(ticket.sig_s,
          '0x03cc65f3e60f1b007609f69f464a1ec2ae10b39805116434f8c647d63c1e7bb6');

      print("Test winner");
      // test winner (values from the JS test)
      expect(ticket.isWinner('0x00'), true);
      expect(ticket.isWinner('0x01'), true);
      expect(ticket.isWinner('0x05'), false);
      expect(ticket.isWinner('0x07'), false);
      expect(ticket.isWinner('0x0D'), true);

    });
  });
}
