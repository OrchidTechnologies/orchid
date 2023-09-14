import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/eth_transaction.dart';
import 'package:orchid/vpn/purchase/orchid_pac_transaction.dart';

import 'expect.dart';

void main() {
  PacTransaction roundTrip(PacTransaction tx) {
    return PacTransaction.fromJson(jsonDecode(jsonEncode(tx)));
  }

  var signer =
      EthereumAddress.from('0x00A0844371B32aF220548DCE332989404Fda2EeF');
  var signerKey = StoredEthereumKey.generate();
  var ethTx = EthereumTransaction(
      params: EthereumTransactionParams(
        from: signer,
        to: EthereumAddress.from("0xA67D6eCAaE2c0073049BB230FB4A8a187E88B77b"),
        gas: 175000,
        gasPrice: BigInt.from(1e9),
        value: BigInt.from(1e18),
        chainId: 100,
      ),
      data: '0x987ff31c000000000...');

  group('Pac transaction should serialize and deserialize correctly', () {
    test('legacy', () {
      // legacy tx
      var legacyJson =
          '{"productId":"1234","transactionId":null,"state":"Pending","receipt":null,"date":"2021-03-01T22:56:14.085235","retries":"0","serverResponse":null}';
      PacTransaction tx1 = PacTransaction.fromJson(jsonDecode(legacyJson));
      expectTrue(tx1.type == PacTransactionType.None);
      expect(tx1.date, isNotNull);
    });

    test('add balance error', () {
      var txIn = PacAddBalanceTransaction.error("error string");
      var tx = roundTrip(txIn) as PacAddBalanceTransaction;
      expectTrue(tx is PacAddBalanceTransaction);
      expect(tx.state, PacTransactionState.Error);
      expect(tx.serverResponse, "error string");
      expect(tx.signer, null);
    });

    test('seller tx', () {
      var params = ethTx.params;
      var sellerTx = PacSubmitSellerTransaction(
        signerKey: signerKey.ref(),
        txParams: params,
        escrow: BigInt.from(123),
      );

      sellerTx = roundTrip(sellerTx) as PacSubmitSellerTransaction;
      expect(sellerTx.state, PacTransactionState.Pending);
      expectTrue(sellerTx is PacSubmitSellerTransaction);
      expectTrue(
          sellerTx.txParams.toJson().toString() == params.toJson().toString());
      expectTrue(sellerTx.txParams == params);
      expect(sellerTx.escrow, equals(BigInt.from(123)));
      // print(submitRawTx.tx.toJson().toString());
    });

    test('add balance receipt', () {
      var tx =
          PacAddBalanceTransaction.pending(signer: signer, productId: "1234");

      tx = roundTrip(tx) as PacAddBalanceTransaction;
      expectTrue(tx is PacAddBalanceTransaction);
      expect(tx.productId, "1234");
      expect(tx.state, PacTransactionState.Pending);
      expect(tx.date, isNotNull);
      expect(tx.signer, signer);

      tx.retries = 3;
      tx.receipt = "receipt";
      tx = roundTrip(tx) as PacAddBalanceTransaction;
      expect(tx.retries, 3);
      expect(tx.receipt, "receipt");
    });

    test('purchase combined', () {
      var addBalance =
          PacAddBalanceTransaction.pending(signer: signer, productId: "1234");
      var submitRaw = PacSubmitSellerTransaction(
          signerKey: signerKey.ref(),
          txParams: ethTx.params,
          escrow: BigInt.zero);
      var tx = PacPurchaseTransaction(addBalance, submitRaw);

      var receipt = 'receipt:' + ('x' * 7000) + 'y';
      tx.addReceipt(receipt, ReceiptType.ios);

      tx = roundTrip(tx) as PacPurchaseTransaction;

      expect(tx.addBalance, equals(addBalance));
      expect(tx.submitRaw, equals(submitRaw));

      addBalance = tx.addBalance;
      submitRaw = tx.submitRaw;
      expectTrue(tx is PacPurchaseTransaction);
      expectTrue(addBalance is PacAddBalanceTransaction);
      expectTrue(submitRaw is PacSubmitSellerTransaction);
      expect(addBalance.productId, "1234");
      expect(submitRaw.txParams, ethTx.params);
      expect(tx.type, PacTransactionType.PurchaseTransaction);
      expect(tx.state, PacTransactionState.Ready);
      expect(tx.date, isNotNull);
      expect(tx.receipt, receipt);
      expect(tx.receiptType, ReceiptType.ios);
    });

    test('raw eth tx round trip', () {
      var txOut = EthereumTransaction.fromJson(jsonDecode(jsonEncode(ethTx)));
      expectTrue(ethTx.params.from == txOut.params.from);
      expectTrue(ethTx.params.to == txOut.params.to);
      expectTrue(ethTx.params.gas == txOut.params.gas);
      expectTrue(ethTx.params.gasPrice == txOut.params.gasPrice);
      expectTrue(ethTx.params.value == txOut.params.value);
      expectTrue(ethTx.params.chainId == txOut.params.chainId);
      expectTrue(ethTx.data == txOut.data);
      expect(txOut.toJson().toString(), isNot(contains("nonce")));
    });

    test('raw eth tx round trip 2', () {
      var txIn = EthereumTransaction(
        params: EthereumTransactionParams(
            from: EthereumAddress.from(
                "0x00A0844371B32aF220548DCE332989404Fda2EeF"),
            to: EthereumAddress.from(
                "0xA67D6eCAaE2c0073049BB230FB4A8a187E88B77b"),
            gas: 175000,
            gasPrice: BigInt.from(1e9),
            value: BigInt.from(1e18),
            chainId: 100),
        data: '0x987ff31c000000000...',
        nonce: 1,
      );

      var txOut = EthereumTransaction.fromJson(jsonDecode(jsonEncode(txIn)));
      expectTrue(txIn == txOut);
      expectTrue(txIn.toJson().toString() == txOut.toJson().toString());
      expect(txOut.params.chainId, equals(100));
      expect(txOut.nonce, equals(1));
    });

    //
  });
}
