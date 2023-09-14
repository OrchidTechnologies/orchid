import 'dart:async';
import 'dart:convert';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/eth_transaction.dart';
import 'package:orchid/api/orchid_language.dart';
import 'package:orchid/api/orchid_platform.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/vpn/preferences/user_preferences_vpn.dart';
import 'package:orchid/vpn/orchid_api.dart';
import 'package:orchid/util/hex.dart';
import 'package:orchid/util/json.dart';

enum PacTransactionType {
  /// Legacy transaction
  None,

  /// Establish or add to balance on the server by submitting an IAP receipt
  AddBalance,

  /// Utilize balance on the server to submit a transaction
  SubmitSellerTransaction,

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
  String? serverResponse;

  // If this is part of a composite transaction this is the container
  PacTransaction? _parent;

  /// The shared, single, outstanding PAC transaction or null if there is none.
  static ObservablePreference<PacTransaction?> get shared {
    return UserPreferencesVPN().pacTransaction;
  }

  PacTransaction({
    required this.type,
    required this.state,
    DateTime? date,
    this.retries = 0,
    this.serverResponse,
  }) : this.date = date ?? DateTime.now();

  PacTransaction.error(
      {required String message, required PacTransactionType type})
      : this(
            type: type,
            state: PacTransactionState.Error,
            serverResponse: message);

  PacTransaction error(String message) {
    this.state = PacTransactionState.Error;
    this.serverResponse = message;
    return this;
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'state': state.name,
        'date': date.toIso8601String(),
        'retries': retries.toString(),
        'serverResponse': serverResponse
      };

  PacTransaction.fromJsonBase(Map<String, dynamic> json,
      {PacTransaction? parent})
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
      case PacTransactionType.AddBalance:
        return PacAddBalanceTransaction.fromJson(json);
      case PacTransactionType.SubmitSellerTransaction:
        return PacSubmitSellerTransaction.fromJson(json);
      case PacTransactionType.PurchaseTransaction:
        return PacPurchaseTransaction.fromJson(json);
    }
  }

  Future<String> userDebugString() async {
    var json = toJson();
    json['os'] = OrchidPlatform.operatingSystem;
    json['locale'] = OrchidLanguage.staticLocale.toString();
    json['appVersion'] = await OrchidAPI().versionString();
    return jsonEncode(json);
  }

  @override
  String toString() {
    return 'PacTransaction' + Json.trimLongStrings(toJson()).toString();
  }

  PacTransaction ready() {
    this.state = PacTransactionState.Ready;
    return this;
  }

  Future<PacTransaction?> save() async {
    return shared.set(_parent != null ? _parent : this);
  }

  // Return the state matching the string name ignoring case
  static PacTransactionState toTransactionState(String s) {
    return PacTransactionState.values.byName(s);
  }

  // Return the transaction type matching the string name ignoring case
  static PacTransactionType? toTransactionType(String? s) {
    if (s == null) {
      return null;
    }
    return PacTransactionType.values.byName(s);
  }
}

class PacAddBalanceTransaction extends PacTransaction
    implements ReceiptTransaction {
  EthereumAddress? signer;
  String productId;
  String? receipt;
  ReceiptType? receiptType;

  PacAddBalanceTransaction.pending(
      {required EthereumAddress signer, required String productId})
      : this.signer = signer,
        this.productId = productId,
        super(
          type: PacTransactionType.AddBalance,
          state: PacTransactionState.Pending,
        );

  PacAddBalanceTransaction.error(String message)
      : this.productId = '',
        super.error(
          message: message,
          type: PacTransactionType.AddBalance,
        );

  /// Add the receipt and advance the state to ready
  PacTransaction addReceipt(String receipt, ReceiptType receiptType) {
    this.receipt = receipt;
    this.receiptType = receiptType;
    this.state = PacTransactionState.Ready;
    return this;
  }

  @override
  PacAddBalanceTransaction.fromJson(Map<String, dynamic> json,
      {PacTransaction? parent})
      : signer = EthereumAddress.fromNullable(json['signer']),
        productId = json['productId'],
        receipt = json['receipt'],
        receiptType = ReceiptType.values.byName(json['receiptType'] ?? 'none'),
        super.fromJsonBase(json, parent: parent);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PacAddBalanceTransaction &&
          runtimeType == other.runtimeType &&
          signer == other.signer &&
          productId == other.productId &&
          receipt == other.receipt;

  @override
  int get hashCode => signer.hashCode ^ productId.hashCode ^ receipt.hashCode;

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'signer': signer.toString(),
      'productId': productId,
      'receipt': receipt,
      'receiptType': receiptType != null ? receiptType!.name : null,
    });
    return json;
  }
}

enum ReceiptType {
  none,
  // ios in-app purchase receipt
  ios,
  // android play store in-app purchase receipt
  android,
}

// Interface
abstract class ReceiptTransaction extends PacTransaction {
  ReceiptTransaction({required super.type, required super.state});

  String? get receipt;

  ReceiptType? get receiptType;

  PacTransaction addReceipt(String receipt, ReceiptType receiptType);
}

/// Encapsulates a raw on-chain transaction for submission to the pac server,
/// which will sign and fund its submission.
// Technically could be called PacSubmitRawTransactionTransaction :)
class PacSubmitSellerTransaction extends PacTransaction {
  StoredEthereumKeyRef signerKey;
  EthereumTransactionParams txParams;

  // Application-specific parameters to be encoded into the edit call.
  // These cannot be baked into a data string because they include nonces
  // that must be signed at submit time.
  BigInt escrow;

  PacSubmitSellerTransaction({
    required this.signerKey,
    required this.txParams,
    required this.escrow,
  }) : super(
          state: PacTransactionState.Pending,
          type: PacTransactionType.SubmitSellerTransaction,
        );

  @override
  PacSubmitSellerTransaction.fromJson(Map<String, dynamic> json,
      {PacTransaction? parent})
      : txParams = EthereumTransactionParams.fromJson(json['txParams']),
        signerKey = StoredEthereumKeyRef(json['signerKeyUid']),
        escrow = BigInt.parse(json['escrow']),
        super.fromJsonBase(json, parent: parent);

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'txParams': txParams,
      'signerKeyUid': signerKey.keyUid,
      'escrow': Hex.hex(escrow), // 0x...
    });
    return json;
  }

  /// Escaped json string with EIP-191 version E.
  static String encodePacTransactionString(Map<String, dynamic> json) {
    return jsonEncode(json).replaceAll("'", '"').replaceAll(' ', '');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PacSubmitSellerTransaction &&
          runtimeType == other.runtimeType &&
          signerKey == other.signerKey &&
          txParams == other.txParams;

  @override
  int get hashCode => signerKey.hashCode ^ txParams.hashCode;
}

/// Combines a add balance and a submit raw transaction to fund an account.
class PacPurchaseTransaction extends PacTransaction
    implements ReceiptTransaction {
  late PacAddBalanceTransaction addBalance;
  late PacSubmitSellerTransaction submitRaw;

  PacPurchaseTransaction(this.addBalance, this.submitRaw)
      : super(
          type: PacTransactionType.PurchaseTransaction,
          state: PacTransactionState.Pending,
        );

  @override
  String? get receipt {
    return addBalance.receipt;
  }

  @override
  ReceiptType? get receiptType {
    return addBalance.receiptType;
  }

  @override
  PacTransaction addReceipt(String receipt, ReceiptType receiptType) {
    this.addBalance.addReceipt(receipt, receiptType);
    this.state = PacTransactionState.Ready;
    return this;
  }

  @override
  PacPurchaseTransaction.fromJson(Map<String, dynamic> json)
      : super.fromJsonBase(json) {
    this.addBalance =
        PacAddBalanceTransaction.fromJson(json['addBalance'], parent: this);
    this.submitRaw =
        PacSubmitSellerTransaction.fromJson(json['submitRaw'], parent: this);
  }

  @override
  Map<String, dynamic> toJson() {
    var json = super.toJson();
    json.addAll({
      'type': type.name,
      'addBalance': addBalance,
      'submitRaw': submitRaw,
    });
    return json;
  }
}
