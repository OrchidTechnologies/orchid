import 'dart:async';
import 'package:in_app_purchase/store_kit_wrappers.dart';
import 'package:orchid/util/units.dart';
import '../orchid_log_api.dart';
import 'orchid_pac.dart';
import 'orchid_pac_server.dart';
import 'orchid_purchase.dart';

class IOSOrchidPurchaseAPI
    implements OrchidPurchaseAPI, SKTransactionObserverWrapper {
  /// Default prod service endpoint configuration.
  /// May be overridden in configuration with e.g.
  /// 'pacs = {
  ///    enabled: true,
  ///    url: 'https://sbdds4zh8a.execute-api.us-west-2.amazonaws.com/dev/apple',
  ///    verifyReceipt: false,
  ///    debug: true
  ///  }'
  static PACApiConfig prodAPIConfig = PACApiConfig(
      enabled: true,
      url: 'https://veagsy1gee.execute-api.us-west-2.amazonaws.com/prod/apple');

  /// Return the API config allowing overrides from configuration.
  @override
  Future<PACApiConfig> apiConfig() async {
    return OrchidPurchaseAPI.apiConfigWithOverrides(prodAPIConfig);
  }

  @override
  void initStoreListener() async {
    log("iap: init store listener");
    SKPaymentQueueWrapper().setTransactionObserver(this);

    // Log all PAC Tx activity for now
    await PacTransaction.shared.ensureInitialized();
    PacTransaction.shared.stream().listen((PacTransaction tx) {
      log("iap: PAC Tx updated: ${tx == null ? '(no tx)' : tx}");
    });

    // Note: This is an attempt to mitigate an "unable to connect to iTunes Store"
    // Note: error observed in TestFlight by starting the connection process earlier.
    // Note: Products are otherwise fetched immediately prior to purchase.
    await requestProducts();

    // Reset any existing tx after an app restart.
    var pacTx = await PacTransaction.shared.get();
    if (pacTx != null) {
      log("iap: Found PAC tx in progress after app startup.");
      pacTx.state = PacTransactionState.WaitingForUserAction;
      pacTx.save();
    }
  }

  /// Initiate a PAC purchase. The caller should watch PacTransaction.shared
  /// for progress and results.
  Future<void> purchase(PAC pac) async {
    log("iap: purchase pac");
    if (!await OrchidPurchaseAPI.isWithinPurchaseRateLimit(pac)) {
      throw PACPurchaseExceedsRateLimit();
    }

    // Refresh the products list:
    // Note: Doing this on app start does not seem to be sufficient.
    await requestProducts();

    // Ensure no other transaction is pending completion.
    if (await PacTransaction.shared.hasValue()) {
      throw Exception('PAC transaction already in progress.');
    }
    var payment = SKPaymentWrapper(productIdentifier: pac.productId);
    try {
      log("iap: add payment to queue");
      await SKPaymentQueueWrapper().addPayment(payment);
      PacTransaction.pending(pac.productId).save();
    } catch (err) {
      log("Error adding payment to queue: $err");
      // The exception will be handled by the calling UI. No tx started.
      rethrow;
    }
  }

  /// Gather results of an in-app purchase.
  @override
  void updatedTransactions(
      {List<SKPaymentTransactionWrapper> transactions}) async {
    log("iap: received (${transactions.length}) updated transactions");
    for (SKPaymentTransactionWrapper tx in transactions) {
      switch (tx.transactionState) {
        case SKPaymentTransactionStateWrapper.purchasing:
          log("iap: IAP purchasing state");
          break;

        case SKPaymentTransactionStateWrapper.restored:
          // Are we getting this on a second purchase attempt that we dropped?
          // Attempting to just handle it as a new purchase for now.
          log("iap: iap purchase restored?");
          _completeIAPTransaction(tx);
          break;

        case SKPaymentTransactionStateWrapper.purchased:
          log("iap: IAP purchased state");
          try {
            await SKPaymentQueueWrapper().finishTransaction(tx);
          } catch (err) {
            log("iap: error finishing purchased tx: $err");
          }
          _completeIAPTransaction(tx);
          break;

        case SKPaymentTransactionStateWrapper.failed:
          log("iap: IAP failed state");

          log("iap: finishing failed tx");
          try {
            await SKPaymentQueueWrapper().finishTransaction(tx);
          } catch (err) {
            log("iap: error finishing cancelled tx: $err");
          }

          if (tx.error?.code == OrchidPurchaseAPI.SKErrorPaymentCancelled) {
            log("iap: was cancelled");
            PacTransaction.shared.clear();
          } else {
            log("iap: IAP Failed, ${tx.toString()} error: type=${tx.error.runtimeType}, code=${tx.error.code}, userInfo=${tx.error.userInfo}, domain=${tx.error.domain}");
            PacTransaction.shared.set(PacTransaction.error("iap failed"));
          }
          break;

        case SKPaymentTransactionStateWrapper.deferred:
          log("iap: iap deferred");
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
      log("iap: Found completed iap purchase with no pending PAC tx. Cleaning.");
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
      log("iap: error getting receipt data for comleted iap");
    }

    OrchidPACServer().processPendingPACTransaction();
  }

  @override
  Future<Map<String, PAC>> requestProducts() async {
    var productIds = [
      OrchidPurchaseAPI.pacTier1,
      OrchidPurchaseAPI.pacTier2,
      OrchidPurchaseAPI.pacTier3
    ];
    log("iap: product ids requested: $productIds");
    SkProductResponseWrapper productResponse =
        await SKRequestMaker().startProductRequest(productIds);
    log("iap: product response: ${productResponse.products.map((p) => p.productIdentifier)}");

    var findProd = (String id) {
      return productResponse.products
          .firstWhere((p) => p.productIdentifier == id);
    };
    var pac1 = findProd(OrchidPurchaseAPI.pacTier1);
    var pac2 = findProd(OrchidPurchaseAPI.pacTier2);
    var pac3 = findProd(OrchidPurchaseAPI.pacTier3);
    if (pac1.priceLocale.currencyCode != "USD") {
      throw Exception('unknown currency product response');
    }
    log("pac1 = ${pac1.productIdentifier}, ${pac1.price}, ${pac1.priceLocale}");
    log("pac2 = ${pac2.productIdentifier}, ${pac2.price}, ${pac2.priceLocale}");
    log("pac3 = ${pac3.productIdentifier}, ${pac3.price}, ${pac3.priceLocale}");

    var toPAC = (SKProductWrapper prod) {
      return PAC(
          productId: prod.productIdentifier,
          usdPurchasePrice: USD(double.parse(prod.price)),
          displayName: "\$${prod.price} USD");
    };
    return {
      pac1.productIdentifier: toPAC(pac1),
      pac2.productIdentifier: toPAC(pac2),
      pac3.productIdentifier: toPAC(pac3),
    };
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
    log("removed transactions: $transactions");
  }

  @override
  void restoreCompletedTransactionsFailed({SKError error}) {
    log("restore failed");
  }
}
