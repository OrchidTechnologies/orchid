import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/preferences/user_secure_storage.dart';
import 'package:orchid/api/purchase/purchase_rate.dart';
import 'package:orchid/util/units.dart';
import '../orchid_platform.dart';
import 'android_purchase.dart';
import 'ios_purchase.dart';
import 'orchid_pac.dart';
import '../orchid_log_api.dart';

/// Support in-app purchase of purchased access credits (PACs).
/// @See the iOS and Android implementations of this class.
abstract class OrchidPurchaseAPI {
  static OrchidPurchaseAPI _shared;

  factory OrchidPurchaseAPI() {
    if (_shared == null) {
      if (OrchidPlatform.isApple) {
        _shared = IOSOrchidPurchaseAPI();
      } else if (OrchidPlatform.isAndroid) {
        _shared = AndroidOrchidPurchaseAPI();
      } else {
        throw Exception('no purchase on platform');
      }
    }
    return _shared;
  }

  // Domain used in product ID prefix, e.g. 'net.orchid'
  static String productIdPrefix = 'net.orchid';

  // PAC product ids
  static List<String> pacProductIds = [
    OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier4',
    OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier10',
    OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier11',
  ];

  // The raw value from the iOS API
  static const int SKErrorPaymentCancelled = 2;

  Future<PacApiConfig> apiConfig();

  void initStoreListener();

  Future<Map<String, PAC>> requestProducts({bool refresh = false});

  /// Make the app store purchase. This method will throw
  /// PACPurchaseExceedsRateLimit if the daily purchase rate has been exceeded.
  Future<void> purchase(PAC pac);

  /// Return the API config allowing overrides from configuration.
  static Future<PacApiConfig> apiConfigWithOverrides(
      PacApiConfig prodAPIConfig) async {
    var jsConfig = await OrchidUserConfig().getUserConfigJS();
    return PacApiConfig(
      enabled: jsConfig.evalBoolDefault('pacs.enabled', prodAPIConfig.enabled),
      url: jsConfig.evalStringDefault('pacs.url', prodAPIConfig.url),
      verifyReceipt: jsConfig.evalBoolDefault(
          'pacs.verifyReceipt', prodAPIConfig.verifyReceipt),
      testReceipt: jsConfig.evalStringDefault('pacs.receipt', prodAPIConfig.testReceipt),
      debug: jsConfig.evalBoolDefault('pacs.debug', prodAPIConfig.debug),
      serverFail:
          jsConfig.evalBoolDefault('pacs.serverFail', prodAPIConfig.debug),
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
    var jsConfig = await OrchidUserConfig().getUserConfigJS();
    var overrideDailyPurchaseLimit = jsConfig.evalDoubleDefault(
        'pacs.pacDailyPurchaseLimit', pacDailyPurchaseLimit.value);
    var dailyPurchaseLimit =
        min(overrideDailyPurchaseLimit, pacDailyPurchaseLimit.value);

    log("isWithinPurchaseRateLimit: limit = $dailyPurchaseLimit, "
        "current = ${history.sum()}, history = ${history.toJson()}");

    return history.sum() + pac.usdPriceExact.value <= dailyPurchaseLimit;
  }

  /// Record a purchase in the PAC purchase rate limit history.
  static void addPurchaseToRateLimit(PAC pac) async {
    PurchaseRateHistory history =
        await UserSecureStorage().getPurchaseRateHistory();
    history.removeOlderThan(Duration(days: 1));
    history.add(pac);
    history.save();
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
  final String testReceipt;

  /// Enable debug tracing.
  final bool debug;

  /// Simulate PAC server failure redeeming receipt
  final bool serverFail;

  PacApiConfig({
    @required this.url,
    this.enabled = true,
    this.verifyReceipt = true,
    this.testReceipt,
    this.debug = false,
    this.serverFail = false,
  });
}

class PACPurchaseExceedsRateLimit implements Exception {}
