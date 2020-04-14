import 'dart:async';
import 'package:in_app_purchase/store_kit_wrappers.dart';
import 'orchid_pac.dart';
import 'orchid_pac_server.dart';
import 'orchid_purchase.dart';

class IOSOrchidPurchaseAPI
    implements OrchidPurchaseAPI, SKTransactionObserverWrapper {
  @override
  initStoreListener() async {
    print("iap: init store listener");
    SKPaymentQueueWrapper().setTransactionObserver(this);

    // Log all PAC Tx activity for now
    await PacTransaction.shared.ensureInitialized();
    PacTransaction.shared.stream().listen((PacTransaction tx) {
      print("iap: PAC Tx updated: ${tx == null ? '(no tx)' : tx}");
    });

    // Reset any existing tx after an app restart.
    var pacTx = await PacTransaction.shared.get();
    if (pacTx != null) {
      print("iap: Found PAC tx in progress after app startup.");
      pacTx.state = PacTransactionState.WaitingForUserAction;
      pacTx.save();
    }
  }

  /// Initiate a PAC purchase. The caller should watch PacTransaction.shared
  /// for progress and results.
  Future<void> purchase(PAC pac) async {
    print("iap: purchase pac");

    // Refresh the products list:
    // Note: Doing this on app start does not seem to be sufficient.
    await _requestProducts();

    // Ensure no other transaction is pending completion.
    if (await PacTransaction.shared.hasValue()) {
      throw Exception("PAC transaction already in progress.");
    }
    var payment = SKPaymentWrapper(productIdentifier: pac.productId);
    try {
      print("iap: add payment to queue");
      await SKPaymentQueueWrapper().addPayment(payment);
      PacTransaction.pending(pac.productId).save();
    } catch (err) {
      print("Error adding payment to queue: $err");
      // The exception will be handled by the calling UI. No tx started.
      rethrow;
    }
  }

  /// Gather results of an in-app purchase.
  @override
  void updatedTransactions(
      {List<SKPaymentTransactionWrapper> transactions}) async {
    print("iap: received (${transactions.length}) updated transactions");
    for (SKPaymentTransactionWrapper tx in transactions) {
      switch (tx.transactionState) {
        case SKPaymentTransactionStateWrapper.purchasing:
          print("iap: IAP purchasing state");
          break;

        case SKPaymentTransactionStateWrapper.restored:
          // Are we getting this on a second purchase attempt that we dropped?
          // Attempting to just handle it as a new purchase for now.
          print("iap: iap purchase restored?");
          _completeIAPTransaction(tx);
          break;

        case SKPaymentTransactionStateWrapper.purchased:
          print("iap: IAP purchased state");
          try {
            await SKPaymentQueueWrapper().finishTransaction(tx);
          } catch (err) {
            print("iap: error finishing purchased tx: $err");
          }
          _completeIAPTransaction(tx);
          break;

        case SKPaymentTransactionStateWrapper.failed:
          print("iap: IAP failed state");

          print("iap: finishing failed tx");
          try {
            await SKPaymentQueueWrapper().finishTransaction(tx);
          } catch (err) {
            print("iap: error finishing cancelled tx: $err");
          }

          if (tx.error?.code == OrchidPurchaseAPI.SKErrorPaymentCancelled) {
            print("iap: was cancelled");
            PacTransaction.shared.clear();
          } else {
            print(
                "iap: IAP Failed, ${tx.toString()} error: type=${tx.error.runtimeType}, code=${tx.error.code}, userInfo=${tx.error.userInfo}, domain=${tx.error.domain}");
            PacTransaction.shared.set(PacTransaction.error("iap failed"));
          }
          break;

        case SKPaymentTransactionStateWrapper.deferred:
          print("iap: iap deferred");
          break;
      }
    }
  }

  // The IAP is complete, update the PAC transaction status.
  Future _completeIAPTransaction(SKPaymentTransactionWrapper tx) async {
    // Update the stored PAC tx
    var pacTx = await PacTransaction.shared.get();

    // Recover from a re-install with a completed iap pending
    if (pacTx == null) {
      print(
          "iap: Found completed iap purchase with no pending PAC tx. Cleaning.");
      // Note: If this happens we have lost the receipt data in the bundle.
      // Note: For now let's assume the user wanted out and finish the tx.
      await PacTransaction.shared.clear();
      return;
    }

    // Attach the receipt
    try {
      pacTx.receipt = await SKReceiptManager.retrieveReceiptData();
      pacTx.save();
    } catch (err) {
      print("iap: error getting receipt data for comleted iap");
    }

    OrchidPACServer().processPendingPACTransaction();
  }

  Future<void> _requestProducts() async {
    var productIds = [
      OrchidPurchaseAPI.pacTier1.productId,
      OrchidPurchaseAPI.pacTier2.productId,
      OrchidPurchaseAPI.pacTier3.productId
    ];
    print("iap: product ids requested: $productIds");
    SkProductResponseWrapper productResponse =
        await SKRequestMaker().startProductRequest(productIds);
    print(
        "iap: product response: ${productResponse.products.map((p) => p.productIdentifier)}");
  }

  @override
  bool shouldAddStorePayment(
      {SKPaymentWrapper payment, SKProductWrapper product}) {
    return true;
  }

  @override
  void paymentQueueRestoreCompletedTransactionsFinished() {}

  @override
  void removedTransactions({List<SKPaymentTransactionWrapper> transactions}) {
    print("removed transactions: $transactions");
  }

  @override
  void restoreCompletedTransactionsFailed({SKError error}) {
    print("restore failed");
  }
}
