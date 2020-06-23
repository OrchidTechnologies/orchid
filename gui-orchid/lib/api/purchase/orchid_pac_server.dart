import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:orchid/api/configuration/orchid_vpn_config.dart';
import '../orchid_log_api.dart';
import 'orchid_pac.dart';
import 'orchid_purchase.dart';

/// The PAC service exchanges an in-app purchase receipt for an Orchid PAC.
class OrchidPACServer {
  static final OrchidPACServer _shared = OrchidPACServer._internal();

  factory OrchidPACServer() {
    return _shared;
  }

  OrchidPACServer._internal();

  /// Process the current PAC transaction if required. This method can be
  /// called at any time to attempt to move the process to the next state.
  void processPendingPACTransaction() async {
    log("iap: process pending pac tx");
    var tx = await PacTransaction.shared.get();
    if (tx == null) {
      log("iap: pac tx null, return");
      return;
    }
    switch (tx.state) {
      case PacTransactionState.InProgress:
      case PacTransactionState.Error:
      case PacTransactionState.Complete:
        // Nothing to be done.
        log("iap: nothing to do");
        return;
        break;
      case PacTransactionState.WaitingForRetry:
        log("iap: retry");
        tx.retries++;
        continue nextCase;
      nextCase:
      case PacTransactionState.Pending:
      case PacTransactionState.WaitingForUserAction:
        log("iap: pending or waiting for user: go");
        break;
    }

    // Begin processing the PAC tx
    log("iap: set pac tx to in-progress");
    tx.state = PacTransactionState.InProgress;
    await tx.save(); // update the UI

    // Submit to the server
    try {
      String response = await _submitToPACServer(tx);
      // Success: store the response.
      tx.serverResponse = response;
      tx.state = PacTransactionState.Complete;
    } catch (err) {
      // Server error
      log("iap: error in pac submit: $err");
      tx.serverResponse = "$err";

      // Schedule retry
      if (tx.retries < 2) {
        log("iap: scheduling retry");
        // Schedule a retry
        tx.state = PacTransactionState.WaitingForRetry;
        var delay = Duration(seconds: 5); // TODO
        Future.delayed(delay).then((_) {
          processPendingPACTransaction();
        });
      } else {
        // Wait for user action
        log("iap: waiting for user action");
        tx.state = PacTransactionState.WaitingForUserAction;
      }
    }

    // Publish the transaction status
    await tx.save();
  }

  /// Submit an app store receipt to the PAC server and return the full server response.
  /// An exception is thrown on any server response that does not contain a valid PAC.
  Future<String> _submitToPACServer(PacTransaction tx) async {
    log("iap: submit to PAC server");
    var apiConfig = await OrchidPurchaseAPI().apiConfig();

    if (apiConfig.serverFail) {
      await Future.delayed(Duration(seconds: 3));
      throw Exception('Testing server failure!');
    }

    if (tx.receipt == null) {
      log('iap: null receipt');
      throw Exception('receipt is null');
    }

    Map<String, String> params = {};

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

    // TESTING
    //await Future.delayed(Duration(seconds: 1), () {});
    //throw Exception("testing");

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
}
