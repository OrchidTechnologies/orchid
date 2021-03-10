/// Hide these from the CI server
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/eth_transaction.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/api/orchid_eth/v1/orchid_contract_v1.dart';
import 'package:orchid/api/pricing/orchid_pricing.dart';
import 'package:orchid/api/purchase/orchid_pac_server.dart';
import 'package:orchid/api/purchase/orchid_purchase.dart';

///
/// Server integration tests
///
void main() async {
  // Disable for the CI
  const bool disabled = true;
  if (disabled) {
    print("Disabled.");
    return;
  }

  // Un-mock the http client
  // TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _TestHttpOverrides();

  var signer =
      EthereumAddress.from('0x92cFa426Cb13Df5151aD1eC8865c5C6841546603');
  var receipt = (await File('test/receipt_local.txt').readAsString()).trim();

  PacApiConfig apiConfig = PacApiConfig(
      url: 'https://sbdds4zh8a.execute-api.us-west-2.amazonaws.com/dev');

  group('Pac server', () {
    //

    test('get balance', () async {
      print("Get balance...");
      await OrchidPACServer().getBalance(signer: signer, apiConfig: apiConfig);
      print("Get balance complete...");
    });

    test('add balance', () async {
      print("Add balance...");
      await OrchidPACServer()
          .addBalance(signer: signer, receipt: receipt, apiConfig: apiConfig);
      print("Add balance complete...");
    });

    test('submit raw tx', () async {
      print("Submit raw...");
      var adjust = BigInt.from(1e17); // 0.1
      var retrieve = BigInt.from(0);
      // A move transaction
      EthereumTransaction tx = EthereumTransaction(
        from: signer,
        // lottery contract address v1 (in flux)
        to: EthereumAddress.from("0xA67D6eCAaE2c0073049BB230FB4A8a187E88B77b"),
        gas: 175000,
        gasPrice: BigInt.from(1e9),
        value: BigInt.from(1e18),
        chainId: Chains.xDAI.chainId,
        // No nonce
        // nonce: ...
        data: OrchidContractV1.abiEncodeMove(signer, adjust, retrieve),
      );

      await OrchidPACServer().submitRawTransaction(
          signer: signer,
          chainId: Chains.xDAI.chainId,
          tx: tx,
          apiConfig: apiConfig);
      print("Submit raw complete...");
    });

    test('get Binance exchange rate', () async {
      var price = await OrchidPricing().tokenToUsdRate(TokenTypes.XDAI);
      price = await OrchidPricing().tokenToUsdRate(TokenTypes.XDAI);
      print("xdai to usd = $price");
    });

    //
  });
}

class _TestHttpOverrides extends HttpOverrides {}
