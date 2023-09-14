import 'dart:async';
import 'dart:math';
import 'package:orchid/api/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/vpn/preferences/user_secure_storage.dart';
import 'package:orchid/vpn/orchid_api.dart';
import 'package:orchid/vpn/purchase/purchase_rate.dart';
import 'android_purchase.dart';
import 'ios_purchase.dart';
import 'orchid_pac.dart';
import 'orchid_pac_server.dart';
import 'orchid_pac_transaction.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/api/pricing/usd.dart';

/// Support in-app purchase of purchased access credits (PACs).
/// @See the iOS and Android implementations of this class.
abstract class OrchidPurchaseAPI {
  static OrchidPurchaseAPI? _shared;

  factory OrchidPurchaseAPI() {
    if (_shared == null) {
      if (OrchidPlatform.isApple || OrchidAPI.mockAPI) {
        _shared = IOSOrchidPurchaseAPI();
      } else if (OrchidPlatform.isAndroid) {
        _shared = AndroidOrchidPurchaseAPI();
      } else {
        throw Exception('no purchase on platform');
      }
    }
    return _shared!;
  }

  OrchidPurchaseAPI.internal();

  // Domain used in product ID prefix, e.g. 'net.orchid'
  static String productIdPrefix = 'net.orchid';

  // PAC product ids
  static List<String> pacProductIds = [
    OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier4',
    OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier10',
    OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier11',
  ];

  Future<PacApiConfig> apiConfig();

  Future<void> initStoreListener() async {
    log("iap: init store listener");

    OrchidPurchaseAPI.initPacLogListener();

    // if (!OrchidAPI.mockAPI || allowPurchaseWithMock) {
    if (!OrchidAPI.mockAPI) {
      await initStoreListenerImpl();
    }

    // Note: Products are also fetched immediately prior to purchase.
    try {
      await requestProducts();
    } catch (err) {
      log("iap: error in request products: $err");
    }

    await OrchidPurchaseAPI.recoverTx();
  }

  Future<void> initStoreListenerImpl();

  // Return a map of PAC by product id
  Future<Map<String, PAC>> requestProducts({bool refresh = false});

  /// Make the app store purchase. This method will throw
  /// PACPurchaseExceedsRateLimit if the daily purchase rate has been exceeded.
  /// Initiate a PAC purchase. The caller should watch PacTransaction.shared
  /// for progress and results.
  Future<void> purchase(PAC pac) async {
    log("iap: purchase pac");

    // Mock support
    // if (OrchidAPI.mockAPI && !allowPurchaseWithMock) {
    if (OrchidAPI.mockAPI) {
      log("iap: mock purchase, delay");
      Future.delayed(Duration(seconds: 2)).then((_) async {
        log("iap: mock purchase, advance with receipt");
        // The receipt may be overridden for testing with pac.receipt
        OrchidPACServer()
            .advancePACTransactionsWithReceipt('mock receipt', ReceiptType.ios);
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

    if (PacTransaction.shared.hasValue()) {
      log('iap: : PAC transaction in progress');
    }

    await purchaseImpl(pac);
  }

  Future<void> purchaseImpl(PAC pac);

  /// Return the API config allowing overrides from configuration.
  static Future<PacApiConfig> apiConfigWithOverrides(
      PacApiConfig prodAPIConfig) async {
    var jsConfig = OrchidUserConfig().getUserConfig();
    return PacApiConfig(
      enabled: jsConfig.evalBoolDefault('pacs.enabled', prodAPIConfig.enabled),
      url: jsConfig.evalStringDefault('pacs.url', prodAPIConfig.url),
      verifyReceipt: jsConfig.evalBoolDefault(
          'pacs.verifyReceipt', prodAPIConfig.verifyReceipt),
      testReceipt:
          jsConfig.evalStringDefaultNullable('pacs.receipt', prodAPIConfig.testReceipt),
      debug: jsConfig.evalBoolDefault('pacs.debug', prodAPIConfig.debug),
      serverFail: jsConfig.evalBoolDefault('pacs.serverFail', prodAPIConfig.debug),
    );
  }

  /// Daily per-device PAC purchase limit in USD.
  static const pacDailyPurchaseLimit = USD(200.0);

  /// Return true if the prospective purchase is allowed within the restrictions
  /// of the PAC purchase rate limit.
  static Future<bool> isWithinPurchaseRateLimit(PAC pac) async {
    PurchaseRateHistory history =
        await UserSecureStorage().getPurchaseRateHistory();
    history.removeOlderThan(Duration(days: 1));

    /// Optionally override to lower the PAC daily purchase limit.
    /// Note: This can never raise the limit.
    var jsConfig = await OrchidUserConfig().getUserConfig();
    var overrideDailyPurchaseLimit = jsConfig.evalDoubleDefault(
        'pacs.pacDailyPurchaseLimit', pacDailyPurchaseLimit.value);
    var dailyPurchaseLimit =
        min(overrideDailyPurchaseLimit, pacDailyPurchaseLimit.value);

    log("isWithinPurchaseRateLimit: limit = $dailyPurchaseLimit, "
        "current = ${history.sum()}, history = ${history.toJson()}");

    return history.sum() + pac.usdPriceExact.value <= dailyPurchaseLimit;
  }

  static Future addPurchaseToRateLimit(String productId) async {
    // Record the purchase for rate limiting
    try {
      Map<String, PAC> productMap = await OrchidPurchaseAPI().requestProducts();
      PAC? pac = productMap[productId];
      if (pac == null) {
        throw Exception('no PAC for product id');
      }

      PurchaseRateHistory history =
          await UserSecureStorage().getPurchaseRateHistory();
      history.removeOlderThan(Duration(days: 1));
      history.add(pac);
      history.save();
    } catch (err) {
      log("pac: Unable to find pac for product id!");
    }
  }

  static Future<void> recoverTx() async {
    // Reset any existing tx after an app restart.
    var tx = PacTransaction.shared.get();
    if (tx != null && tx.state != PacTransactionState.Complete) {
      log("iap: Found PAC tx in progress after app startup: $tx");
      tx.state = PacTransactionState.WaitingForUserAction;
      await tx.save();
    }
  }

  static Future initPacLogListener() async {
    // Log all PAC Tx activity for now
    PacTransaction.shared.stream().listen((PacTransaction? tx) {
      log("iap: PAC Tx updated: ${tx == null ? '(no tx)' : tx}");
    });
  }

  // Note: currently hardcoded
  // Return the exact USD price of the product
  static USD usdPriceForProduct(String productId) {
    final priceMap = {
      OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier4': USD(0.99),
      OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier10': USD(4.99),
      OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier11': USD(19.99),
    };
    var price = priceMap[productId];
    if (price == null) {
      throw Exception("No price known for product id: $productId");
    }
    return price;
  }

  // TODO: Clean this up
  static String pacTierDollarProductId =
      OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier4';

  static Future<PAC> getDollarPAC() async {
    try {
      Map<String, PAC> pacs = await OrchidPurchaseAPI().requestProducts();
      var pac = pacs[OrchidPurchaseAPI.pacTierDollarProductId];
      if (pac == null) {
        throw Exception("No PAC for product id: $pacTierDollarProductId");
      }
      return pac;
    } catch (err) {
      log("iap: error requesting products purchase: $err");
      throw err;
    }
  }

  // TODO: Clean this up
  static pacForTier(Iterable<PAC> pacs, int tier) {
    var pacTier = OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier$tier';
    return pacs.firstWhere((pac) => pac.productId == pacTier);
  }

  static Map<String, PAC> mockPacs() {
    var price = 0.99;
    var pacs = [
      PAC(
        productId: OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier4',
        // localCurrencyCode: "EUR",
        // localCurrencySymbol: '€',
        localCurrencyCode: "USD",
        localCurrencySymbol: '\$',
        localPrice: price,
        usdPriceExact: USD(price),
      ),
      PAC(
        productId: OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier10',
        localCurrencyCode: "USD",
        localCurrencySymbol: '\$',
        localPrice: price,
        usdPriceExact: USD(price),
      ),
      PAC(
        productId: OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier11',
        localCurrencyCode: "EUR",
        localCurrencySymbol: '€',
        localPrice: price,
        usdPriceExact: USD(price),
      ),
    ];
    return {for (var pac in pacs) pac.productId: pac};
  }
}

class PacApiConfig {
  /// Platform-specific PAC Server URL
  /// e.g. 'https://veagsy1gee.execute-api.us-west-2.amazonaws.com/prod/apple'
  final String url;

  /// Feature flag for PACs
  final bool enabled;

  /// Optionally disable receipt verification in dev.
  final bool verifyReceipt;

  // If configured the test receipt will be submitted with all calls.
  final String? testReceipt;

  /// Enable debug tracing.
  final bool debug;

  /// Simulate PAC server failure redeeming receipt
  final bool serverFail;

  PacApiConfig({
    required this.url,
    this.enabled = true,
    this.verifyReceipt = true,
    this.testReceipt,
    this.debug = false,
    this.serverFail = false,
  });
}

class PACPurchaseExceedsRateLimit implements Exception {}

//class UserCancelledException implements Exception { }
