import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:orchid/api/purchase/orchid_pac_transaction.dart';

// See https://pub.dev/packages/test
void main() {
  PacTransaction roundTrip(PacTransaction tx) {
    return PacTransaction.fromJson(jsonDecode(jsonEncode(tx)));
  }

  group('Pac transaction should serialize and deserialize correctly', () {
    test('legacy', () {
      // legacy tx
      var legacyJson =
          '{"productId":"1234","transactionId":null,"state":"PacTransactionStateV0.Pending","receipt":null,"date":"2021-03-01T22:56:14.085235","retries":"0","serverResponse":null}';
      PacTransaction tx1 = PacTransaction.fromJson(jsonDecode(legacyJson));
      expectTrue(tx1.type == PacTransactionType.None);
      expect(tx1.date, isNotNull);
    });

    test('tx', () {
      var txIn = PacAddBalanceTransaction.error("error string");
      PacAddBalanceTransaction tx = roundTrip(txIn);
      expectTrue(tx is PacAddBalanceTransaction);
      expect(tx.state, PacTransactionState.Error);
      expect(tx.serverResponse, "error string");
    });

    test('tx2', () {
      var tx = PacSubmitRawTransaction("rawtx");
      tx = roundTrip(tx);
      expect(tx.state, PacTransactionState.Pending);
      expectTrue(tx is PacSubmitRawTransaction);
    });

    test('tx3', () {
      var tx = PacAddBalanceTransaction.pending(productId: "1234");

      tx = roundTrip(tx);
      expectTrue(tx is PacAddBalanceTransaction);
      expect(tx.productId, "1234");
      expect(tx.state, PacTransactionState.Pending);
      expect(tx.date, isNotNull);

      tx.retries = 3;
      tx.receipt = "receipt";
      tx = roundTrip(tx);
      expect(tx.retries, 3);
      expect(tx.receipt, "receipt");
    });

    test('purchase combined', () {
      String rawTransaction = '{1234...}';
      var addBalance = PacAddBalanceTransaction.pending(productId: "1234");
      var submitRaw = PacSubmitRawTransaction(rawTransaction);
      var tx = PacPurchaseTransaction(addBalance, submitRaw);
      print("tx before = ${tx.toJson()}");
      tx.addReceipt("receipt");
      tx = roundTrip(tx);
      print("tx after = ${tx.toJson()}");
      addBalance = tx.addBalance;
      submitRaw = tx.submitRaw;
      expectTrue(tx is PacPurchaseTransaction);
      expectTrue(addBalance is PacAddBalanceTransaction);
      expectTrue(submitRaw is PacSubmitRawTransaction);
      expect(addBalance.productId, "1234");
      expect(submitRaw.rawTransaction, rawTransaction);
      expect(tx.type, PacTransactionType.PurchaseTransaction);
      expect(tx.state, PacTransactionState.Pending);
      expect(tx.date, isNotNull);
      expect(tx.receipt, "receipt");
    });
  });
}

void expectTrue(dynamic cond) {
  expect(cond, true);
}
