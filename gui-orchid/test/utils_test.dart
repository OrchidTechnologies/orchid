import 'dart:convert';

import 'package:flutter_js/flutter_js.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchid/api/orchid_user_config/orchid_account_import.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/tokens.dart';
import 'package:orchid/vpn/purchase/orchid_pac_transaction.dart';
import 'package:orchid/util/cacheable.dart';
import 'package:orchid/util/json.dart';
import 'package:orchid/util/strings.dart';
import 'package:orchid/api/pricing/usd.dart';
import 'expect.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('test utils', () {
    //

    test('import account1', () {
      // TEST account config text: random, not real accounts.
      final config = 'account='
          '{ funder: "0x6dd46c5f9f19ab8790f6249322f58028a3185087", secret: "3d15ba96c0aa8eff04f6df30d5e2d03f63c288d37dd5bef5c370274f9b76c747", chainid: 100, version: 1 }';
      final account = OrchidAccountImport.parseSingleOrchidAccount(config, []);
      print("account = $account");
    });

    test('import account2', () {
      // TEST account config text: random, not real accounts.
      final config = 'accounts=[ '
          '{ funder: "0x6dd46c5f9f19ab8790f6249322f58028a3185087", secret: "3d15ba96c0aa8eff04f6df30d5e2d03f63c288d37dd5bef5c370274f9b76c747", chainid: 100, version: 1 },'
          '{ funder: "0x7dd46c5f9f19ab8790f6249322f58028a3185087", secret: "c1f10dcf9133671051065231311315270ecd04cc5545fc3a151504bcb9d7813e", chainid: 100, version: 1 }, '
          ']';
      final accounts =
          OrchidAccountImport.parseMultipleOrchidAccounts(config, []);
      print("accounts = $accounts");
    });

    test('enums', () {
      // expect(Enums.toStringValue(PacTransactionType.None), equals('None'));
      expect(PacTransactionType.None.name, equals('None'));
      // expect(Enums.fromString(PacTransactionType.values, 'None'), equals(PacTransactionType.None));
      expect(PacTransactionType.values.byName('None'),
          equals(PacTransactionType.None));
      // expect(Enums.fromString(PacTransactionType.values, 'none'), equals(PacTransactionType.None));
      // expect(PacTransactionType.values.byName('none'), equals(PacTransactionType.None));
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

    test('eth address length 0', () {
      // leading zeroes
      var addrIn = '0x0001B26998dc278a176Ef20b35dAb092741d9BC3';
      var addrOut = EthereumAddress.from(addrIn).toString(prefix: true);
      print(addrOut);
      expect(addrIn.toLowerCase(), equals(addrOut.toLowerCase()));
    });

    test('eth address length from bigint', () {
      var addrIn = BigInt.zero;
      var addrOut = EthereumAddress(addrIn);
      print(addrOut);
      expect(addrOut.toString(), equals(EthereumAddress.zero.toString()));
    });

    /*
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
     */

    test('misc', () async {
      var currency = Chains.Gnosis.nativeCurrency;
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

    test('trim long values in nested json', () async {
      var receipt =
          'MIIT0wYJKoZIhvcNAQcCoIITxDCCE8ACAQExCzAJBgUrDgMCGgUAMIIDdAYJKoZIhvcNAQcBoIIDZQSCA2ExggNdMAoCAQgCAQEEAhYAMAoCARQCAQEEAgwAMAsCAQECAQEEAwIBADALAgELAgEBBAMCAQAwCwIBDwIBAQQDAgEAMAsCARACAQEEAwIBADALAgEZAgEBBAMCAQMwDAIBCgIBAQQEFgI0KzAMAgEOAgEBBAQCAgDPMA0CAQ0CAQEEBQIDAfz9MA0CARMCAQEEBQwDMS4wMA4CAQkCAQEEBgIEUDI1MzAYAgEEAgECBBCcYZTNCNSnk8yiOD6j3CIqMBoCAQMCAQEEEgwQNDcuNTUyMjIzLjk5MDAxNDAbAgEAAgEBBBM,';
      var json = {
        'name': "Kate",
        'foo': {
          'a': 'foostring',
          'bar': {
            'receipt': receipt,
            'b': 'barstring',
          }
        }
      };
      print(Json.trimLongStrings(json));
    });

    test('strings', () async {
      expect("foobar".prefix(3, elide: "..."), equals("foo..."));
      expect("foobar".suffix(3), equals("bar"));
    });

    test('cache', () async {
      var func = (TokenType key) async {
        return 42;
      };
      Cache<TokenType, int> cache = Cache(duration: Duration(seconds: 2));
      await cache.get(key: Tokens.ETH, producer: func);
      await cache.get(key: Tokens.ETH, producer: func);
      await cache.get(key: Tokens.ETH, producer: func);
      await Future.delayed(Duration(seconds: 2));
      await cache.get(key: Tokens.ETH, producer: func);
      await cache.get(key: Tokens.ETH, producer: func);
    });

    test('js util test', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final jsEngine =
          getJavascriptRuntime(forceJavascriptCoreOnAndroid: false);
      JsEvalResult eval = jsEngine.evaluate("42.0;");
      print(eval);
      eval = jsEngine.evaluate("true");
      print(eval);
      eval = jsEngine.evaluate("[1,2,3]");
      print(eval.runtimeType);
      print(eval.rawResult.runtimeType);
    });

    test('js util test 2', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      var js = """
      accounts = [
        {
          secret:"0xfb5d5...",
          funder: "0x1234...",
          version: 1,
          chainid: 100,
        },
        {
          secret:"0xeb5d5...",
          funder: "0x2235...",
          version: 1,
          chainid: 100,
        },
      ]
      """;
      final jsEngine =
          getJavascriptRuntime(forceJavascriptCoreOnAndroid: false);
      JsEvalResult eval = jsEngine.evaluate(js);
      eval = jsEngine.evaluate("JSON.stringify(accounts)");
      var json = jsonDecode(eval.toString());
      for (var account in json) {
        print(account['version'].runtimeType);
      }
    });

    test('js util test 3', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Note: Not a real key, just for testing.
      var js = 'account={ secret: "128967e28f170a389664e98a701781de4cb18f6f1a1ba00ca4bdd62dd92430c3" }';
      final jsEngine = getJavascriptRuntime(forceJavascriptCoreOnAndroid: false);
      JsEvalResult eval = jsEngine.evaluate(js);
      eval = jsEngine.evaluate("account.secret");
      print(eval.toString());
      eval = jsEngine.evaluate("account.foo");
      print("account.foo = " +eval.toString());
      try {
        eval = jsEngine.evaluate("bar");
      }catch(err) {
        print("error fetching bar = " +err.toString());
      }
      print("bar = " +eval.toString());
    });

    //
  });
}
