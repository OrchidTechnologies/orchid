import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/vpn/orchid_api.dart';
import 'dart:async';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'orchid_pac.dart';
import 'orchid_pac_transaction.dart';
import 'orchid_purchase.dart';
import 'orchid_pac_server.dart';

class IOSOrchidPurchaseAPI extends OrchidPurchaseAPI
    implements SKTransactionObserverWrapper {
  IOSOrchidPurchaseAPI() : super.internal();

  /// Default prod service endpoint configuration.
  /// May be overridden in configuration with e.g.
  /// 'pacs = {
  ///    enabled: true,
  ///    url: 'https://xxx.amazonaws.com/dev',
  ///    debug: true
  ///  }'
  static PacApiConfig prodAPIConfig =
      PacApiConfig(url: 'https://api.orchid.com/pac');

  // The raw value from the iOS API
  // https://developer.apple.com/documentation/storekit/skerror/code
  static const int SKErrorPaymentCancelled = 2;

  // https://developer.apple.com/documentation/cfnetwork/cfnetworkerrors/kcfurlerrordatanotallowed
  static const int kCFURLErrorDataNotAllowed = -1020;

  /// Return the API config allowing overrides from configuration.
  @override
  Future<PacApiConfig> apiConfig() async {
    return OrchidPurchaseAPI.apiConfigWithOverrides(prodAPIConfig);
  }

  @override
  Future<void> initStoreListenerImpl() async {
    SKPaymentQueueWrapper().setTransactionObserver(this);
    await SKPaymentQueueWrapper().startObservingTransactionQueue();
    final pendingTx = await SKPaymentQueueWrapper().transactions();
    if ((pendingTx ?? []).isNotEmpty) {
      log("iap: Pending transactions exist on start!: $pendingTx");
      updatedTransactions(transactions: pendingTx);
    }
  }

  @override
  Future<void> purchaseImpl(PAC pac) async {
    var payment = SKPaymentWrapper(productIdentifier: pac.productId);
    try {
      log('iap: add payment to queue');
      await SKPaymentQueueWrapper().addPayment(payment);
    } catch (err) {
      log('Error adding payment to queue: $err');
      // The exception will be handled by the calling UI. No tx started.
      rethrow;
    }
  }

  /// Gather results of an in-app purchase.
  @override
  void updatedTransactions(
      {required List<SKPaymentTransactionWrapper> transactions}) async {
    log('iap: received (${transactions.length}) updated transactions');
    for (SKPaymentTransactionWrapper tx in transactions) {
      switch (tx.transactionState) {
        case SKPaymentTransactionStateWrapper.purchasing:
          log('iap: IAP purchasing state');
          if (PacTransaction.shared.get() == null) {
            log('iap: Unexpected purchasing state.');
            // TODO: We'd like to salvage the receipt but what identity should we use?
            // PacAddBalanceTransaction.pending(
            //     signer: signer, productId: tx.payment.productIdentifier).save();
          }
          break;

        case SKPaymentTransactionStateWrapper.restored:
          log('iap: iap purchase restored?');
          // Attempting to just handle it as a new purchase for now.
          _completeIAPTransaction(tx);
          break;

        case SKPaymentTransactionStateWrapper.purchased:
          log('iap: IAP purchased state');
          await _completeIAPTransaction(tx);

          try {
            await SKPaymentQueueWrapper().finishTransaction(tx);
          } catch (err) {
            log('iap: error finishing purchased tx: $err');
          }
          break;

        case SKPaymentTransactionStateWrapper.failed:
          log('iap: IAP failed state.');
          log('iap: finishing failed tx');

          // We must finish even failed transactions.
          try {
            await SKPaymentQueueWrapper().finishTransaction(tx);
          } catch (err) {
            log('iap: error finishing cancelled tx: $err');
          }

          switch (tx.error?.code) {
            case SKErrorPaymentCancelled:
              log('iap: was cancelled');
              PacTransaction.shared.clear();
              break;
            case kCFURLErrorDataNotAllowed:
              // The behavior here seems to be that we will get another update
              // with the purchased state when connectivity is restored.
              log('iap: failed due to network connectivity. Expect another update.');
              // Show the transaction in progress.
              var pacTx = PacTransaction.shared.get();
              if (pacTx == null) {
                log("expected pac transaction but none found.");
              } else {
                pacTx.state = PacTransactionState.InProgress;
                pacTx.save();
              }
              break;
            default:
              // Unknown error.
              log('iap: IAP Failed, ${tx.toString()} error: type=${tx.error.runtimeType}, code=${tx.error?.code}, userInfo=${tx.error?.userInfo}, domain=${tx.error?.domain}');
              var pacTx = PacTransaction.shared.get();
              if (pacTx == null) {
                log("expected pac transaction but none found.");
              } else {
                pacTx.error('IAP failed, reason unknown.').save();
              }
              break;
          }
          break;

        case SKPaymentTransactionStateWrapper.deferred:
          log('iap: iap deferred');
          break;

        case SKPaymentTransactionStateWrapper.unspecified:
          log('iap: transaction in unknown state: $tx, ${tx.error}');
          var pacTx = PacTransaction.shared.get();
          if (pacTx == null) {
            log("expected pac transaction but none found.");
          } else {
            pacTx.error('iap failed: unknown state').save();
          }
          break;
      }
    }
  }

  // The IAP is complete, update AML and the pending transaction status.
  Future _completeIAPTransaction(SKPaymentTransactionWrapper tx) async {
    log('iap: Completing transaction');

    // Record the purchase for rate limiting
    OrchidPurchaseAPI.addPurchaseToRateLimit(tx.payment.productIdentifier);

    // Get the receipt
    try {
      log('iap: getting receipt');
      String receipt = await SKReceiptManager.retrieveReceiptData();

      // If the receipt is null, try to refresh it.
      // (This might happen if there was a purchase in flight during an upgrade.)
      /*
      if (receipt == null) {
        log('iap: receipt null, refreshing');
        try {
          await SKRequestMaker().startRefreshReceiptRequest();
        } catch (err) {
          log('iap: Error in refresh receipt request');
        }
        receipt = await SKReceiptManager.retrieveReceiptData();
      }
       */

      // If the receipt is still null there's not much we can do.
      /*
      if (receipt == null) {
        log('iap: Completed purchase but no receipt found! Clearing transaction.');
        await PacTransaction.shared.clear();
        return;
      }
       */

      // Pass the receipt to the pac system
      return OrchidPACServer()
          .advancePACTransactionsWithReceipt(receipt, ReceiptType.ios);
    } catch (err) {
      log('iap: error getting receipt data for completed iap: $err');
    }
  }

  static Map<String, PAC>? productsCached;

  // Return a map of PAC by product id
  @override
  Future<Map<String, PAC>> requestProducts({bool refresh = false}) async {
    // if (OrchidAPI.mockAPI && !OrchidPurchaseAPI.allowPurchaseWithMock) {
    if (OrchidAPI.mockAPI) {
      return OrchidPurchaseAPI.mockPacs();
    }
    if (productsCached != null && !refresh) {
      log('iap: returning cached products');
      return productsCached!;
    }

    var productIds = OrchidPurchaseAPI.pacProductIds;
    log('iap: product ids requested: $productIds');
    SkProductResponseWrapper productResponse =
        await SKRequestMaker().startProductRequest(productIds);
    log('iap: product response: ${productResponse.products.map((p) => p.productIdentifier)}');

    var toPAC = (SKProductWrapper prod) {
      double localizedPrice = double.parse(prod.price);
      String currencyCode = prod.priceLocale.currencyCode;
      String currencySymbol = prod.priceLocale.currencySymbol;
      var productId = prod.productIdentifier;
      return PAC(
        productId: productId,
        localPrice: localizedPrice,
        localCurrencyCode: currencyCode,
        localCurrencySymbol: currencySymbol,
        usdPriceExact: OrchidPurchaseAPI.usdPriceForProduct(productId),
      );
    };

    var pacs = productResponse.products.map(toPAC).toList();
    Map<String, PAC> products = {for (var pac in pacs) pac.productId: pac};
    productsCached = products;
    log('iap: returning products: $products');
    return products;
  }

  @override
  bool shouldAddStorePayment(
      {required SKPaymentWrapper payment, required SKProductWrapper product}) {
    log('iap: Should add store payment: $payment, for product: $product');
    return true;
  }

  @override
  void paymentQueueRestoreCompletedTransactionsFinished() {
    log('iap: paymentQueueRestoreCompletedTransactionsFinished');
  }

  @override
  void removedTransactions({required List<SKPaymentTransactionWrapper> transactions}) {
    log('iap: removed transactions: $transactions');
  }

  @override
  void restoreCompletedTransactionsFailed({required SKError error}) {
    log('iap: restore failed');
  }
}
