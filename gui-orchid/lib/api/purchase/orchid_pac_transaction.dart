import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/util/enums.dart';

enum PacTransactionType {
  /// Legacy transaction
  None,

  /// Establish or add to balance on the server by submitting an IAP receipt
  AddBalance,

  /// Utilize balance on the server to submit a transaction
  SubmitRawTransaction,

  /// Combines an add balance and submit raw transaction into one operation
  PurchaseTransaction,
}

/// A PAC transaction is created in the Pending state. When its prerequisites are
/// fulfilled (e.g. an IAP is completed and it is assigned a receipt) it enters
/// the Ready state. A PAC transaction that has failed any automatic retries
/// enters the WaitingForUserAction state.  The transaction ends in either the
/// Complete or Error state.  In either case the serverResponse contains the
/// final resolution and after inspection / retrieval the transaction can be cleared.
enum PacTransactionState {
  None,
  Pending,
  Ready,
  InProgress,
  WaitingForRetry,
  WaitingForUserAction,
  Error,
  Complete
}

/// A PacTransaction represents a pending transaction with the PAC server.
class PacTransaction {
  final PacTransactionType type;
  PacTransactionState state;
  DateTime date;
  int retries;
  String serverResponse;

  // If this is part of a composite transaction this is the container
  PacTransaction _parent;

  /// The shared, single, outstanding PAC transaction or null if there is none.
  static ObservablePreference<PacTransaction> get shared {
    return UserPreferences().pacTransaction;
  }

  PacTransaction({
    @required this.type,
    @required this.state,
    this.date,
    this.retries = 0,
    this.serverResponse,
  }) {
    date = date ?? DateTime.now();
  }

  PacTransaction.error(
      {@required String message, @required PacTransactionType type})
      : this(
            type: type,
            state: PacTransactionState.Error,
            serverResponse: message);

  Map<String, dynamic> toJson() => {
        'type': Enums.toStringValue(type),
        'state': Enums.toStringValue(state),
        'date': date.toIso8601String(),
        'retries': retries.toString(),
        'serverResponse': serverResponse
      };

  PacTransaction.fromJsonBase(Map<String, dynamic> json,
      {PacTransaction parent})
      : type = toTransactionType(json['type']) ?? PacTransactionType.None,
        state = toTransactionState(json['state']),
        date = DateTime.parse(json['date']),
        retries = int.parse(json['retries'] ?? "0"),
        serverResponse = json['serverResponse'],
        _parent = parent;

  static PacTransaction fromJson(Map<String, dynamic> json) {
    var type = toTransactionType(json['type']) ?? PacTransactionType.None;
    switch (type) {
      case PacTransactionType.None:
        return PacTransaction.fromJsonBase(json);
        break;
      case PacTransactionType.AddBalance:
        return PacAddBalanceTransaction.fromJson(json);
        break;
      case PacTransactionType.SubmitRawTransaction:
        return PacSubmitRawTransaction.fromJson(json);
        break;
      case PacTransactionType.PurchaseTransaction:
        return PacPurchaseTransaction.fromJson(json);
        break;
    }
    throw Exception("Unknown transaction type: $json");
  }

  String userDebugString() {
    return toJson().toString();
  }

  @override
  String toString() {
    return 'PacTransaction' + trimValues(toJson()).toString();
  }

  PacTransaction ready() {
    this.state = PacTransactionState.Ready;
    return this;
  }

  Future<PacTransaction> save() async {
    return shared.set(_parent != null ? _parent : this);
  }

  // Return the state matching the string name ignoring case
  static PacTransactionState toTransactionState(String s) {
    return Enums.fromString(PacTransactionState.values, s);
  }

  // Return the transaction type matching the string name ignoring case
  static PacTransactionType toTransactionType(String s) {
    return Enums.fromString(PacTransactionType.values, s);
  }

  // Trim long string values for e.g. logging purposes
  static Map<String, dynamic> trimValues(Map<String, dynamic> json,
      {int max: 1024}) {
    return json.map((String key, dynamic value) {
      if (value.toString().length > max) {
        value = value.toString().substring(0, max) + '...';
      }
      return MapEntry(key, value);
    });
  }
}

class PacAddBalanceTransaction extends PacTransaction
    implements ReceiptTransaction {
  String productId;
  String transactionId;
  String receipt;

  PacAddBalanceTransaction.pending({String productId})
      : super(
          type: PacTransactionType.AddBalance,
          state: PacTransactionState.Pending,
        ) {
    this.productId = productId;
  }

  PacAddBalanceTransaction.error(String message)
      : super.error(
          message: message,
          type: PacTransactionType.AddBalance,
        );

  /// Add the receipt and advance the state to ready
  PacTransaction addReceipt(String receipt) {
    this.receipt = receipt;
    this.state = PacTransactionState.Ready;
    return this;
  }

  @override
  PacAddBalanceTransaction.fromJson(Map<String, dynamic> json,
      {PacTransaction parent})
      : super.fromJsonBase(json, parent: parent) {
    productId = json['productId'];
    transactionId = json['transactionId'];
    receipt = json['receipt'];
  }

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'productId': productId,
      'transactionId': transactionId,
      'receipt': receipt,
    });
    return json;
  }
}

// Interface
abstract class ReceiptTransaction extends PacTransaction {
  String get receipt;

  PacTransaction addReceipt(String receipt);
}

/// Encapsulates a raw on-chain transaction for submission to the pac server,
/// which will sign and fund its submission.
// Technically could be called PacSubmitRawTransactionTransaction :)
class PacSubmitRawTransaction extends PacTransaction {
  String rawTransaction;

  PacSubmitRawTransaction(String rawTransaction)
      : super(
          state: PacTransactionState.Pending,
          type: PacTransactionType.SubmitRawTransaction,
        ) {
    this.rawTransaction = rawTransaction;
  }

  @override
  PacSubmitRawTransaction.fromJson(Map<String, dynamic> json,
      {PacTransaction parent})
      : super.fromJsonBase(json, parent: parent) {
    rawTransaction = json['rawTransaction'];
  }

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'rawTransaction': rawTransaction,
    });
    return json;
  }
}

/// Combines a add balance and a submit raw transaction to fund an account.
class PacPurchaseTransaction extends PacTransaction
    implements ReceiptTransaction {
  PacAddBalanceTransaction addBalance;
  PacSubmitRawTransaction submitRaw;

  PacPurchaseTransaction(this.addBalance, this.submitRaw)
      : super(
          type: PacTransactionType.PurchaseTransaction,
          state: PacTransactionState.Pending,
        );

  @override
  String get receipt {
    return addBalance.receipt;
  }

  @override
  PacTransaction addReceipt(String receipt) {
    this.addBalance.addReceipt(receipt);
    this.state = PacTransactionState.Ready;
    return this;
  }

  @override
  PacPurchaseTransaction.fromJson(Map<String, dynamic> json)
      : super.fromJsonBase(json) {
    this.addBalance =
        PacAddBalanceTransaction.fromJson(json['addBalance'], parent: this);
    this.submitRaw =
        PacSubmitRawTransaction.fromJson(json['submitRaw'], parent: this);
  }

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'type': Enums.toStringValue(type),
      'addBalance': addBalance,
      'submitRaw': submitRaw,
    });
    return json;
  }
}
