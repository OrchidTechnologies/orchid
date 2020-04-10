import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
    print("iap: process pending pac tx");
    var tx = await PacTransaction.shared.get();
    if (tx == null) {
      print("iap: pac tx null, return");
      return;
    }
    switch (tx.state) {
      case PacTransactionState.InProgress:
      case PacTransactionState.Error:
      case PacTransactionState.Complete:
        // Nothing to be done.
        print("iap: nothing to do");
        return;
        break;
      case PacTransactionState.WaitingForRetry:
        print("iap: retry");
        tx.retries++;
        continue nextCase;
      nextCase:
      case PacTransactionState.Pending:
      case PacTransactionState.WaitingForUserAction:
        print("iap: pending or waiting for user: go");
        break;
    }

    // Begin processing the PAC tx
    print("iap: set pac tx to in-progress");
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
      print("iap: error in pac submit: $err");
      tx.serverResponse = "$err";

      // Schedule retry
      if (tx.retries < 2) {
        print("iap: scheduling retry");
        // Schedule a retry
        tx.state = PacTransactionState.WaitingForRetry;
        var delay = Duration(seconds: 5); // TODO
        Future.delayed(delay).then((_) {
          processPendingPACTransaction();
        });
      } else {
        // Wait for user action
        print("iap: waiting for user action");
        tx.state = PacTransactionState.WaitingForUserAction;
      }
    }

    // Publish the transaction status
    await tx.save();
  }

  /// Submit an app store receipt to the PAC server and return the full server response.
  /// An exception is thrown on any server response that does not contain a valid PAC.
  Future<String> _submitToPACServer(PacTransaction tx) async {
    print("iap: submit to PAC server");
    if (tx.receipt == null) {
      print("iap: null receipt");
      throw Exception("receipt is null");
    }
    var apiConfig = await OrchidPurchaseAPI.apiConfig();

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
    print("iap: posting to ${apiConfig.url}, json = $postBody");

    // TESTING
    //await Future.delayed(Duration(seconds: 1), () {});
    //throw Exception("testing");

    // Do the post
    var response = await http.post(apiConfig.url,
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: postBody);

    // Validate the response status and content
    //print("iap: pac server response: ${response.statusCode}, ${response.body}");
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
