import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:orchid/api/configuration/orchid_vpn_config.dart';
import 'package:orchid/util/units.dart';
import '../orchid_api.dart';

import 'android_purchase.dart';
import 'ios_purchase.dart';
import 'orchid_pac.dart';

/// Support in-app purchase of purchased access credits (PACs).
/// @See the iOS and Android implementations of this class.
abstract class OrchidPurchaseAPI {
  static OrchidPurchaseAPI _shared;

  factory OrchidPurchaseAPI() {
    if (_shared == null) {
      if (Platform.isIOS) {
        _shared = IOSOrchidPurchaseAPI();
      } else if (Platform.isAndroid) {
        _shared = AndroidOrchidPurchaseAPI();
      } else {
        throw Exception("no purchase on platform");
      }
    }
    return _shared;
  }

  // Domain used in product ID prefix, e.g. 'net.orchid'
  static String productIdPrefix = 'net.orchid';

  // PAC product id base name, nominal USD value and display string.
  static PAC pacTier1 = PAC('pactier1', USD(4.99), "\$4.99 USD");
  static PAC pacTier2 = PAC('pactier2', USD(9.99), "\$9.99 USD");
  static PAC pacTier3 = PAC('pactier3', USD(19.99), "\$19.99 USD");

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
      baseUrl: 'https://veagsy1gee.execute-api.us-west-2.amazonaws.com/prod');

  /// Return the API config allowing overrides from configuration.
  static Future<PACApiConfig> apiConfig() async {
    var jsConfig = await OrchidVPNConfig.getUserConfigJS();
    return PACApiConfig(
        enabled: jsConfig.evalBoolDefault('pacs.enabled', prodAPIConfig.enabled),
        baseUrl: jsConfig.evalStringDefault('pacs.url', prodAPIConfig.url),
        verifyReceipt: jsConfig.evalBoolDefault(
            'pacs.verifyReceipt', prodAPIConfig.verifyReceipt),
        debug: jsConfig.evalBoolDefault('pacs.debug', prodAPIConfig.debug));
  }

  // The raw value from the iOS API
  static const int SKErrorPaymentCancelled = 2;

  initStoreListener() {}

  /// Make the app store purchase. The future will resolve when the purchase
  /// has been confirmed and return the store receipt which can then be
  /// submitted to the PAC server for delivery.
  Future<void> purchase(PAC pac);
}

class PACApiConfig {
  // PAC Server URL base (will have platform appended)
  // e.g. 'https://veagsy1gee.execute-api.us-west-2.amazonaws.com/prod" + "/apple'
  final String baseUrl;

  // Platform-specific PAC service URL
  String get url {
    if (Platform.isIOS) {
      return baseUrl + '/apple';
    }
    if (Platform.isAndroid) {
      return baseUrl + '/google';
    }
    throw Exception("unsupported platform");
  }

  // Feature flag for PACs
  final bool enabled;

  // Optionally disable receipt verification in dev.
  final bool verifyReceipt;

  // Enable debug tracing.
  final bool debug;

  PACApiConfig({
    @required this.enabled,
    @required this.baseUrl,
    this.verifyReceipt = true,
    this.debug = false,
  });
}
