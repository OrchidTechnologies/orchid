import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config.dart';
import '../orchid_api.dart';
import '../orchid_log_api.dart';
import 'orchid_pac_transaction.dart';
import 'orchid_purchase.dart';

/// The PAC service exchanges an in-app purchase receipt for an Orchid PAC.
class OrchidPACServer {
  static final OrchidPACServer _shared = OrchidPACServer._internal();

  /// PAC Server status URL
  final String statusUrl =
      'https://veagsy1gee.execute-api.us-west-2.amazonaws.com/prod/status';

  factory OrchidPACServer() {
    return _shared;
  }

  OrchidPACServer._internal();

  /// Apply the receipt to any pending pac receipt transaction and advance it.
  Future<void> advancePACTransactionsWithReceipt(String receipt) async {
    //  Get the current transaction
    var tx = await PacTransaction.shared.get();
    if (tx == null) {
      log("iap: receipt with no corresponding pac tx, attempting to salvage.");
      tx = await PacAddBalanceTransaction.pending(productId: "unknown").save();
    }

    // Attach the receipt
    if (tx is ReceiptTransaction) {
      await tx.addReceipt(receipt).save();
    } else {
      throw Exception("Unknown pending transaction not ready for receipt: $tx");
    }

    return advancePACTransactions();
  }

  /// Process the current PAC transaction if required. This method can be
  /// called at any time to attempt to move the process to the next state.
  Future<void> advancePACTransactions() async {
    log("iap: advance pac transactions");

    var tx = await PacTransaction.shared.get();
    if (tx == null) {
        log("iap: pac tx null, return");
      return;
    }

    switch (tx.state) {
      case PacTransactionState.None:
      case PacTransactionState.Pending:
      case PacTransactionState.InProgress:
      case PacTransactionState.Complete:
      case PacTransactionState.Error:
      case PacTransactionState.WaitingForUserAction:
        // Nothing to be done.
        log("iap: Nothing to do: ${tx.state}");
        return;
        break;
      case PacTransactionState.WaitingForRetry:
        // Assume it's retry time.
        log("iap: retry");
        tx.retries++;
        continue nextCase;
      nextCase:
      case PacTransactionState.Ready:
        log("iap: ready to process");
        break;
    }

    // Begin processing the PAC tx
    log("iap: set pac tx to in-progress");
    tx.state = PacTransactionState.InProgress;
    await tx.save(); // update the UI

    // Submit to the server
    try {
      await apiSupport(); // support testing

      String response;
      switch (tx.type) {
        case PacTransactionType.None:
          log("iap: Unknown transaction type.");
          return;
          break;
        case PacTransactionType.AddBalance:
          response = await _callAddBalance(tx);
          break;
        case PacTransactionType.SubmitRawTransaction:
          response = await _callSubmitRaw(tx);
          break;
        case PacTransactionType.PurchaseTransaction:
          response = await _callPurchase(tx);
          break;
      }

      // Success: store the response.
      tx.serverResponse = response;
      tx.state = PacTransactionState.Complete;
    } catch (err) {
      // Server error
      log("iap: error in pac submit: $err");
      tx.serverResponse = "$err";

      // Schedule retry
      if (tx.retries < 2) {
        log("iap: scheduling retry, delayed");
        tx.state = PacTransactionState.WaitingForRetry;
        var delay = Duration(seconds: 5);
        Future.delayed(delay).then((_) async {
          advancePACTransactions();
        });
      } else {
        log("iap: waiting for user action");
        tx.state = PacTransactionState.WaitingForUserAction;
      }
    }

    await tx.save();
  }

  Future<void> apiSupport() async {
    if (OrchidAPI.mockAPI) {
      log("iap: mock api, delay and throw exception");
      await Future.delayed(Duration(seconds: 2), () {});
      throw Exception("iap: mock api");
    }
    var apiConfig = await OrchidPurchaseAPI().apiConfig();
    if (apiConfig.serverFail) {
      await Future.delayed(Duration(seconds: 2));
      throw Exception('Testing server failure!');
    }
  }

  Future<String> _callAddBalance(PacAddBalanceTransaction tx) async {
    log("iap: submit add balance tx to PAC server");
    if (tx.receipt == null) {
      log('iap: null receipt');
      throw Exception('receipt is null');
    }

    Map<String, String> params = {};
    var apiConfig = await OrchidPurchaseAPI().apiConfig();

    // Optional dev testing params
    if (!apiConfig.verifyReceipt) {
      params.addAll({'verify_receipt': 'False'});
    }
    if (apiConfig.debug) {
      params.addAll({'debug': 'True'});
    }

    // Main params
    params.addAll({'receipt': tx.receipt});

    var postBody = jsonEncode(params);

    // Note: the receipt exceeds the console log line length so keep it last
    // Note: or explicitly truncate it.
    log("iap: posting to ${apiConfig.url}, json = $postBody");

    // Do the post
    var response = await http.post(apiConfig.url,
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: postBody);

    // Validate the response status and content
    //log("iap: pac server response: ${response.statusCode}, ${response.body}");
    if (response.statusCode != 200) {
      throw Exception(
          "Error response: code=${response.statusCode} body=${response.body}");
    }
    var responseJson = json.decode(response.body);
    var configString = responseJson['config'];
    if (configString == null) {
      throw Exception("No config in server response: $response");
    }

    return response.body;
  }

  Future<String> _callSubmitRaw(PacSubmitRawTransaction tx) async {
    log("iap: submit send raw tx to PAC server");

    //return response.body;
    return "test...";
  }

  Future<String> _callPurchase(PacPurchaseTransaction tx) async {
    log("iap: submit purchase tx to PAC server");

    if (tx.addBalance.state != PacTransactionState.Complete) {
      log("iap: purchase tx: add balance");
      tx.addBalance.serverResponse = await _callAddBalance(tx.addBalance);
      tx.addBalance.state = PacTransactionState.Complete;
    }

    log("iap: purchase tx: submit raw");
    tx.submitRaw.serverResponse = await _callSubmitRaw(tx.submitRaw);

    return [tx.addBalance.serverResponse, tx.submitRaw.serverResponse]
        .toString();
  }

  Future<PACStoreStatus> storeStatus() async {
    log("iap: check PAC server status");

    bool overrideDown = (await OrchidVPNConfig.getUserConfigJS())
        .evalBoolDefault('pacs.storeDown', false);
    if (overrideDown) {
      log("iap: override server status");
      return PACStoreStatus.down;
    }

    // Do the post
    var response = await http.get(
      statusUrl,
      headers: {"Content-Type": "application/json; charset=utf-8"},
    );

    // Validate the response status and content
    log("iap: pac server status response: ${response.statusCode}, ${response.body}");
    if (response.statusCode != 200) {
      return PACStoreStatus.down;
    }

    // Safely and conservatively parse bool from the server
    bool Function(Object val, bool defaultValue) parseBool =
        (val, defaultValue) {
      if (val == null) {
        return defaultValue;
      }
      String sval = val.toString().toLowerCase();
      if (sval == "true") {
        return true;
      }
      if (sval == "false") {
        return false;
      }
      return defaultValue;
    };

    var responseJson = json.decode(response.body);
    var disabled = parseBool(responseJson['disabled'], false);

    return PACStoreStatus(open: !disabled);
  }
}

class PACStoreStatus {
  static PACStoreStatus down = PACStoreStatus(open: false);

  // overall store status
  bool open;

  // product status
  //Map<String, bool> product;

  PACStoreStatus({this.open});
}
