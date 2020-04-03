import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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

  // Prod service endpoint configuration.
  static PACApiConfig prodAPIConfig = PACApiConfig(
    endpoint:
        'https://veagsy1gee.execute-api.us-west-2.amazonaws.com/prod/submit',
  );

  // Dev service endpoint configuration: For local development allow use of
  // the dev (OTT) PAC service, optionally turn off receipt validation,
  // and optionally override the product id prefix.
  static PACApiConfig devAPIConfig = PACApiConfig(
    isDev: true,
    endpoint:
        'https://sbdds4zh8a.execute-api.us-west-2.amazonaws.com/dev/submit',
    verifyReceipt: false,
  );

  static Future<PACApiConfig> apiConfig() async {
    bool isDev = ((await OrchidAPI().getConfiguration()) ?? "")
        .contains(RegExp(r'pacs[Ee]nv *= *[Dd]ev'));
    return isDev ? devAPIConfig : prodAPIConfig;
  }

  // Feature flag for testing PAC purchases
  static Future<bool> pacsEnabled() async {
    return ((await OrchidAPI().getConfiguration()) ?? "")
        .contains(RegExp(r'pacs *= *[Tt]rue'));
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
  bool isDev;

  // PAC Server URL
  String endpoint;

  // Optionally disable receipt verification in dev.
  bool verifyReceipt;

  // Optionally disable receipt verification in dev.
  String verifyReceiptValue() {
    return verifyReceipt ? 'True' : 'False';
  }

  PACApiConfig({
    @required this.endpoint,
    this.isDev = false,
    this.verifyReceipt = true,
  });
}
