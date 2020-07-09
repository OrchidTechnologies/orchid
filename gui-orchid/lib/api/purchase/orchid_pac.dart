import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/util/units.dart';
import 'orchid_purchase.dart';

/// A purchased access credit with a localized price and product id.
class PAC {
  String productId;
  double localPurchasePrice;
  String localCurrencyCode; // e.g. "USD"
  String localDisplayPrice;
  USD usdPriceApproximate;

  PAC({
    @required this.productId,
    @required this.localPurchasePrice,
    @required this.localCurrencyCode,
    @required this.localDisplayPrice,
    @required this.usdPriceApproximate,
  });

  @override
  String toString() {
    return 'PAC{_productId: $productId, localPurchasePrice: $localPurchasePrice, localDisplayName: $localDisplayPrice}, usdPriceApproximate: $usdPriceApproximate';
  }
}

/// A PAC transaction is created in the Pending state. IF the IAP succeeds,
/// it is assigned a transaction id and receipt and enters the InProgress state.
/// A PAC transaction that has failed any automatic retries enters the
/// WaitingForUserAction state.  A Complete transaction state indicates a
/// succesfully completed PAC fulfillment which can be retrieved from
/// the serverResponse and subsequently cleared.
enum PacTransactionState {
  Pending,
  InProgress,
  WaitingForRetry,
  WaitingForUserAction,
  Error,
  Complete
}

/// A PacTransaction represents a pending transactions with the PAC server.
/// It is created with the transaction id resulting from an IAP and used
/// to monitor fulfillment.
class PacTransaction {
  DateTime date = DateTime.now();
  String productId;
  String transactionId;
  String receipt;
  PacTransactionState state;
  int retries = 0;
  String serverResponse;

  /// The shared, single, outstanding PAC transaction or null if there is none.
  static ObservablePreference<PacTransaction> get shared {
    return UserPreferences().pacTransaction;
  }

  PacTransaction.pending(String productId) {
    this.state = PacTransactionState.Pending;
    this.productId = productId;
  }

  PacTransaction.error(String msg) {
    this.state = PacTransactionState.Error;
    this.serverResponse = msg;
  }

  PacTransaction.fromJson(Map<String, dynamic> json)
      : productId = json['productId'],
        transactionId = json['transactionId'],
        state = stringToState(json['state']),
        receipt = json['receipt'],
        date = DateTime.parse(json['date']),
        retries = int.parse(json['retries'] ?? "0"),
        serverResponse = json['serverResponse'];

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'transactionId': transactionId,
        'state': state.toString(),
        'receipt': receipt,
        'date': date.toIso8601String(),
        'retries': retries.toString(),
        'serverResponse': serverResponse
      };

  @override
  String toString() {
    return 'PacTransaction{'
        'state: $state, '
        'productId: $productId, '
        'transactionId: $transactionId, '
        'receipt: ${receipt != null ? receipt.substring(0, 32) + '...' : null}, '
        'date: $date, '
        'retries: $retries, '
        'serverResponse: $serverResponse}';
  }

  /// This string is copied to the clipboard by the user when requesting help.
  String userDebugString() {
    return 'PacTransaction{'
        'state: $state, '
        'productId: $productId, '
        'transactionId: $transactionId, '
        'receipt: ${receipt != null ? receipt : null}, '
        'date: $date, '
        'retries: $retries, '
        'serverResponse: $serverResponse}';
  }

  Future<void> save() async {
    return shared.set(this);
  }

  // Return the protocol matching the string name ignoring case
  static PacTransactionState stringToState(String s) {
    return PacTransactionState.values.firstWhere((e) => e.toString() == s,
        orElse: () {
      throw Exception("invalid tx state");
    });
  }
}
