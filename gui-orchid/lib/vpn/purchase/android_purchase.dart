import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/vpn/orchid_api.dart';
import 'orchid_pac.dart';
import 'orchid_pac_server.dart';
import 'orchid_pac_transaction.dart';
import 'orchid_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

class AndroidOrchidPurchaseAPI extends OrchidPurchaseAPI {

  late BillingClient _billingClient;

  AndroidOrchidPurchaseAPI() : super.internal();

  /// Default prod service endpoint configuration.
  /// May be overridden in configuration with e.g.
  /// 'pacs = {
  ///    enabled: true,
  ///    url: 'https://xxx.amazonaws.com/dev',
  ///    debug: true
  ///  }'
  static PacApiConfig prodAPIConfig =
      PacApiConfig(url: 'https://api.orchid.com/pac');

  /// Return the API config allowing overrides from configuration.
  @override
  Future<PacApiConfig> apiConfig() async {
    return OrchidPurchaseAPI.apiConfigWithOverrides(prodAPIConfig);
  }


  @override
  Future<void> initStoreListenerImpl() async {
    try {
      _billingClient = BillingClient(_onPurchaseResult);
      // _billingClient.enablePendingPurchases();
      var billingResult = await _billingClient.startConnection(
          onBillingServiceDisconnected: () {
        log('iap: billing client disconnected');
      });
      
      if (billingResult.responseCode == BillingResponse.ok) {
        log('iap: billing client setup done');
      } else {
        log('iap: Failed to init billing client: ${billingResult.responseCode}');
      }
    } catch (err) {
      log('iap: error initializing billing client: $err');
    }
  }

  @override
  Future<void> purchaseImpl(PAC pac) async {
    var billingResultWrapper =
        await _billingClient.launchBillingFlow(sku: pac.productId);
    log('iap: billing result response = ${billingResultWrapper.responseCode}');
  }

  void _onPurchaseResult(PurchasesResultWrapper purchasesResult) async {
    log('iap: purchase result: $purchasesResult');

    if (purchasesResult.responseCode == BillingResponse.userCanceled) {
      log('iap: was cancelled');
      PacTransaction.shared.clear();
      return;
    }
    if (purchasesResult.responseCode != BillingResponse.ok) {
      log('iap: Error: purchase result response code: ${purchasesResult.responseCode}');
      (PacTransaction.shared.get())
          ?.error('iap failed 1: responseCode = ${purchasesResult.responseCode}')
          .save();
      return;
    }

    var purchases = purchasesResult.purchasesList;
    if (purchases.length > 1) {
      log('iap: unexpected multiple purchases. Clearing: $purchases');
      (PacTransaction.shared.get())?.error('iap failed 2').save();
      for (PurchaseWrapper purchase in purchases) {
        if (purchase.purchaseState != PurchaseStateWrapper.purchased) {
          await _billingClient.consumeAsync(purchase.purchaseToken);
        }
      }
      return;
    }
    if (purchases.isEmpty) {
      log('iap: unexpected purchase empty.');
      (PacTransaction.shared.get())?.error('iap failed 3').save();
      return;
    }
    var purchase = purchases.first;
    log('iap: handling purchase: ${purchase.originalJson}');
    log('iap: purchase package name: ${purchase.packageName}');

    // Acknowledge / 'consume' the purchase: If this is not completed the
    // user will be refunded after a period of time.
    var result = await _billingClient.consumeAsync(purchase.purchaseToken);
    if (result.responseCode == BillingResponse.ok) {
      log('iap: consumeAsync returned ok. Passing receipt.');
      // Get the receipt
      var receipt = purchase.purchaseToken;
      await OrchidPACServer()
          .advancePACTransactionsWithReceipt(receipt, ReceiptType.android);
    } else {
      log('iap: consumeAsync returned error: ${result.responseCode}');
      (PacTransaction.shared.get())?.error('iap failed 4').save();
    }
  }

  @override
  Future<Map<String, PAC>> requestProducts({bool refresh = false}) async {
    if (OrchidAPI.mockAPI) {
      return OrchidPurchaseAPI.mockPacs();
    }
    // if (productsCached != null && !refresh) {
    //   log('iap: returning cached products');
    //   return productsCached;
    // }

    var skuList = OrchidPurchaseAPI.pacProductIds;
    log('iap: product ids requested: $skuList');

    var skuDetailsResponse = await _billingClient.querySkuDetails(
        skuType: SkuType.inapp, skusList: skuList);
    log('iap: sku query billing result: ${skuDetailsResponse.billingResult}');
    log('iap: sku details list: ${skuDetailsResponse.skuDetailsList}');

    var toPAC = (SkuDetailsWrapper prod) {
      double localizedPrice = prod.originalPriceAmountMicros / 1e6;
      String currencyCode = prod.priceCurrencyCode;
      String currencySymbol = prod.price[0];
      log('iap: originalPriceAmountMicros=${prod.originalPriceAmountMicros}, currencyCode=${prod.priceCurrencyCode}, currencySymbol=${prod.price[0]}');
      var productId = prod.sku;
      return PAC(
        productId: productId,
        localPrice: localizedPrice,
        localCurrencyCode: currencyCode,
        localCurrencySymbol: currencySymbol,
        usdPriceExact: OrchidPurchaseAPI.usdPriceForProduct(productId),
      );
    };

    var pacs = skuDetailsResponse.skuDetailsList.map(toPAC).toList();
    Map<String, PAC> products = {for (var pac in pacs) pac.productId: pac};
    //productsCached = products;
    log('iap: returning products: $products');
    return products;
  }
}
