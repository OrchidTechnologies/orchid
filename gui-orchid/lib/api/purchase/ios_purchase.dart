import 'dart:async';
import 'package:in_app_purchase/store_kit_wrappers.dart';
import 'package:orchid/api/pricing/exchange_rates.dart';
import 'package:orchid/util/units.dart';
import '../orchid_api.dart';
import '../orchid_log_api.dart';
import 'orchid_pac.dart';
import 'orchid_pac_server.dart';
import 'orchid_pac_transaction.dart';
import 'orchid_purchase.dart';
import 'package:intl/intl.dart';

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
  static PacApiConfig prodAPIConfig = PacApiConfig(
      // url: 'https://veagsy1gee.execute-api.us-west-2.amazonaws.com/prod/apple',
      // TODO: Dev for this release!
      url: 'https://sbdds4zh8a.execute-api.us-west-2.amazonaws.com/dev');

  /// Return the API config allowing overrides from configuration.
  @override
  Future<PacApiConfig> apiConfig() async {
    return OrchidPurchaseAPI.apiConfigWithOverrides(prodAPIConfig);
  }

  @override
  void initStoreListener() async {
    log("iap: init store listener");

    // Log all PAC Tx activity for now
    await PacTransaction.shared.ensureInitialized();
    PacTransaction.shared.stream().listen((PacTransaction tx) {
      log("iap: PAC Tx updated: ${tx == null ? '(no tx)' : tx}");
    });

    if (!OrchidAPI.mockAPI) {
      SKPaymentQueueWrapper().setTransactionObserver(this);
    }

    // Note: This is an attempt to mitigate an "unable to connect to iTunes Store"
    // Note: error observed in TestFlight by starting the connection process earlier.
    // Note: Products are otherwise fetched immediately prior to purchase.
    try {
      await requestProducts();
    } catch (err) {
      log("iap: error in request products: $err");
    }

    await _recoverTx();
  }

  Future<void> _recoverTx() async {
    // Reset any existing tx after an app restart.
    var tx = await PacTransaction.shared.get();
    if (tx != null && tx.state != PacTransactionState.Complete) {
      log("iap: Found PAC tx in progress after app startup: $tx");
      tx.state = PacTransactionState.WaitingForUserAction;
      return tx.save();
    }
  }

  /// Initiate a PAC purchase. The caller should watch PacTransaction.shared
  /// for progress and results.
  Future<void> purchase(PAC pac) async {
    log("iap: purchase pac");

    // Mock support
    if (OrchidAPI.mockAPI) {
      log("iap: mock purchase, delay");
      Future.delayed(Duration(seconds: 2)).then((_) async {
        log("iap: mock purchase, advance with receipt");
        // The receipt may be overridden for testing with pac.receipt
        OrchidPACServer().advancePACTransactionsWithReceipt("mock receipt");
      });
      return;
    }

    // Check purchase limit
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
          if (PacTransaction.shared.get() == null) {
            log("iap: Unexpected purchasing state.");
            // TODO: We'd like to salvage the receipt but what identity should we use?
            // PacAddBalanceTransaction.pending(
            //     signer: signer, productId: tx.payment.productIdentifier).save();
          }
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
            var pacTx = await PacTransaction.shared.get();
            pacTx.error("iap failed").save();
          }
          break;

        case SKPaymentTransactionStateWrapper.deferred:
          log("iap: iap deferred");
          break;
      }
    }
  }

  // The IAP is complete, update AML and the pending transaction status.
  Future _completeIAPTransaction(SKPaymentTransactionWrapper tx) async {
    // Record the purchase for rate limiting
    var productId = tx.payment.productIdentifier;
    try {
      Map<String, PAC> productMap = await OrchidPurchaseAPI().requestProducts();
      PAC pac = productMap[productId];
      OrchidPurchaseAPI.addPurchaseToRateLimit(pac);
    } catch (err) {
      log("pac: Unable to find pac for product id!");
    }

    // Get the receipt
    try {
      var receipt = await SKReceiptManager.retrieveReceiptData();

      // If the receipt is null, try to refresh it.
      // (This might happen if there was a purchase in flight during an upgrade.)
      if (receipt == null) {
        try {
          await SKRequestMaker().startRefreshReceiptRequest();
        } catch (err) {
          log("iap: Error in refresh receipt request");
        }
        receipt = await SKReceiptManager.retrieveReceiptData();
      }

      // If the receipt is still null there's not much we can do.
      if (receipt == null) {
        log("iap: Completed purchase but no receipt found! Clearing transaction.");
        await PacTransaction.shared.clear();
        return;
      }

      // Pass the receipt to the pac system
      OrchidPACServer().advancePACTransactionsWithReceipt(receipt);
    } catch (err) {
      log("iap: error getting receipt data for completed iap: $err");
    }
  }

  static Map<String, PAC> productsCached;

  @override
  Future<Map<String, PAC>> requestProducts({bool refresh = false}) async {
    if (OrchidAPI.mockAPI) {
      return _mockPacs();
    }
    if (productsCached != null && !refresh) {
      log("iap: returning cached products");
      return productsCached;
    }

    var productIds = OrchidPurchaseAPI.pacProductIds;
    log("iap: product ids requested: $productIds");
    SkProductResponseWrapper productResponse =
        await SKRequestMaker().startProductRequest(productIds);
    log("iap: product response: ${productResponse.products.map((p) => p.productIdentifier)}");

    var toPAC = (SKProductWrapper prod) {
      double localizedPrice = double.parse(prod.price);
      String currencyCode = prod.priceLocale.currencyCode;
      String currencySymbol = prod.priceLocale.currencySymbol;
      return PAC(
          productId: prod.productIdentifier,
          localPrice: localizedPrice,
          localCurrencyCode: currencyCode,
          localCurrencySymbol: currencySymbol,
          usdPriceApproximate: StaticExchangeRates.from(
            price: localizedPrice,
            currencyCode: currencyCode,
          ));
    };

    var pacs = productResponse.products.map(toPAC).toList();
    Map<String, PAC> products = {for (var pac in pacs) pac.productId: pac};
    productsCached = products;
    log("iap: returning products");
    return products;
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

  Map<String, PAC> _mockPacs() {
    var price = 39.99;
    var pacs = [
      PAC(
        productId: OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier4',
        localCurrencyCode: "USD",
        localCurrencySymbol: '\$',
        localPrice: price,
        usdPriceApproximate: USD(price),
      ),
      PAC(
        productId: OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier5',
        localCurrencyCode: "USD",
        localCurrencySymbol: '\$',
        localPrice: price,
        usdPriceApproximate: USD(price),
      ),
      PAC(
        productId: OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier6',
        localCurrencyCode: "EUR",
        localCurrencySymbol: '€',
        localPrice: price,
        usdPriceApproximate: USD(price),
      ),
    ];
    return {for (var pac in pacs) pac.productId: pac};
  }
}

T cast<T>(dynamic x, {T fallback}) => x is T ? x : fallback;
