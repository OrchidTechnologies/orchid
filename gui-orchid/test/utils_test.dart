import 'package:flutter_test/flutter_test.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_contract_v1.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/api/purchase/orchid_pac_transaction.dart';
import 'package:orchid/util/enums.dart';
import 'package:orchid/util/units.dart';

import 'expect.dart';

void main() {
  group('test utils', () {
    //

    test('enums', () {
      expect(Enums.toStringValue(PacTransactionType.None), equals('None'));
      expect(Enums.fromString(PacTransactionType.values, 'None'),
          equals(PacTransactionType.None));
      expect(Enums.fromString(PacTransactionType.values, 'none'),
          equals(PacTransactionType.None));
    });

    test('eth address', () {
      var eip55 = "0xA67D6eCAaE2c0073049BB230FB4A8a187E88B77b";
      var addrIn = EthereumAddress.from(eip55);
      var addrOut = EthereumAddress.from(addrIn.toString(prefix: true));
      expectTrue(addrIn == addrOut);
      addrOut = EthereumAddress.from(addrIn.toString(prefix: false));
      expectTrue(addrIn == addrOut);
      expect(addrIn.toString(prefix: true), startsWith('0x'));
      expect(addrIn.toString(prefix: false), isNot(startsWith('0x')));

      // Tolerate no EIP-55
      var fromNoEip55 = EthereumAddress.from(eip55.toLowerCase());
      expectTrue(addrIn == fromNoEip55);
      // Render to EIP-55
      expectTrue(eip55 == fromNoEip55.toString());
    });

    test('abi encode', () {
      var ref = '0x987ff31c'
          '0000000000000000000000009dc2ab9a2f747b350094715bad80331f996b461b'
          '0000000000000000016345785d8a000000000000000000000000000000000000';
      var signer =
          EthereumAddress.from('0x9DC2AB9a2f747b350094715bAd80331F996b461B');
      var adjust = BigInt.from(1e17);
      var retrieve = BigInt.from(0);
      var data = OrchidContractV1.abiEncodeMove(signer, adjust, retrieve);
      expectTrue(data == ref);
    });

    test('misc', () async {
      var currency = Chains.xDAI.nativeCurrency;
      // var usdToTokenRate = await OrchidPricing().usdToTokenRate(currency);
      var usdToTokenRate = 1.0;
      var totalUsdValue = USD(40);
      var totalTokenValue =
          currency.fromDouble(totalUsdValue.value * usdToTokenRate);
      print("totalTokenValue = " + totalTokenValue.toString());
      print("totalUsdValue = $totalUsdValue, "
          "usdToTokenRate = $usdToTokenRate, "
          "totalTokenValue = $totalTokenValue, ");
    });

    //
  });
}
