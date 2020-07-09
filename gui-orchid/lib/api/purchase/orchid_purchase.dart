import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_vpn_config.dart';
import 'package:orchid/api/preferences/user_secure_storage.dart';
import 'package:orchid/api/purchase/purchase_rate.dart';
import 'package:orchid/util/units.dart';
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
      if (Platform.isIOS | Platform.isMacOS) {
        _shared = IOSOrchidPurchaseAPI();
      } else if (Platform.isAndroid) {
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
  static String pacTier1 = OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier1';
  static String pacTier2 = OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier2';
  static String pacTier3 = OrchidPurchaseAPI.productIdPrefix + '.' + 'pactier3';

  // The raw value from the iOS API
  static const int SKErrorPaymentCancelled = 2;

  Future<PACApiConfig> apiConfig();

  void initStoreListener();

  Future<Map<String,PAC>> requestProducts();

  /// Make the app store purchase. This method will throw
  /// PACPurchaseExceedsRateLimit if the daily purchase rate has been exceeded.
  Future<void> purchase(PAC pac);

  /// Return the API config allowing overrides from configuration.
  static Future<PACApiConfig> apiConfigWithOverrides(
      PACApiConfig prodAPIConfig) async {
    var jsConfig = await OrchidVPNConfig.getUserConfigJS();
    return PACApiConfig(
      enabled: jsConfig.evalBoolDefault('pacs.enabled', prodAPIConfig.enabled),
      url: jsConfig.evalStringDefault('pacs.url', prodAPIConfig.url),
      verifyReceipt: jsConfig.evalBoolDefault(
          'pacs.verifyReceipt', prodAPIConfig.verifyReceipt),
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
    var jsConfig = await OrchidVPNConfig.getUserConfigJS();
    var overrideDailyPurchaseLimit = jsConfig.evalDoubleDefault(
        'pacs.pacDailyPurchaseLimit', pacDailyPurchaseLimit.value);
    var dailyPurchaseLimit =
        min(overrideDailyPurchaseLimit, pacDailyPurchaseLimit.value);

    log("isWithinPurchaseRateLimit: limit = $dailyPurchaseLimit, "
        "current = ${history.sum()}, history = ${history.toJson()}");

    return history.sum() + pac.usdPriceApproximate.value <= dailyPurchaseLimit;
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

class PACApiConfig {
  /// Platform-specific PAC Server URL
  /// e.g. 'https://veagsy1gee.execute-api.us-west-2.amazonaws.com/prod/apple'
  final String url;

  /// Feature flag for PACs
  final bool enabled;

  /// Optionally disable receipt verification in dev.
  final bool verifyReceipt;

  /// Enable debug tracing.
  final bool debug;

  /// Simulate PAC server failure redeeming receipt
  final bool serverFail;

  PACApiConfig({
    @required this.enabled,
    @required this.url,
    this.verifyReceipt = true,
    this.debug = false,
    this.serverFail = false,
  });
}

class PACPurchaseExceedsRateLimit implements Exception {}
