import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:orchid/api/configuration/orchid_vpn_config/orchid_vpn_config.dart';
import 'package:orchid/api/orchid_eth/eth_transaction.dart';
import 'package:orchid/util/units.dart';
import '../orchid_api.dart';
import '../orchid_crypto.dart';
import '../orchid_log_api.dart';
import 'orchid_pac_transaction.dart';
import 'orchid_purchase.dart';
import 'package:orchid/util/strings.dart';

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
  Future<void> advancePACTransactionsWithReceipt(String receiptIn) async {
    // Allow override of receipts with the test receipt.
    var apiConfig = await OrchidPurchaseAPI().apiConfig();
    if (apiConfig.testReceipt != null) {
      log("iap: Using test receipt: ${apiConfig.testReceipt.prefix(8)}");
    }
    var receipt = apiConfig.testReceipt ?? receiptIn;

    //  Get the current transaction
    var tx = await PacTransaction.shared.get();
    if (tx == null) {
      log("iap: receipt with no corresponding pac tx.");
      // TODO: We'd like to salvage the receipt but what identity should we use?
      // tx = await PacAddBalanceTransaction.pending(signer: signer, productId: "unknown").save();
      return;
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
      await _apiSupport(); // support testing

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

  Future<void> _apiSupport() async {
    var apiConfig = await OrchidPurchaseAPI().apiConfig();

    // Fail server calls for the mock api unless we have a test receipt
    if (OrchidAPI.mockAPI && apiConfig.testReceipt == null) {
      log("iap: mock api, delay and throw exception");
      await Future.delayed(Duration(seconds: 2), () {});
      throw Exception("iap: mock api");
    }

    // Fail if we are configured to fail
    if (apiConfig.serverFail) {
      await Future.delayed(Duration(seconds: 2));
      throw Exception('iap: mock failure!');
    }
  }

  Future<String> _callAddBalance(PacAddBalanceTransaction tx) async {
    log("iap: submit add balance tx to PAC server");
    if (tx.receipt == null) {
      log('iap: null receipt');
      throw Exception('receipt is null');
    }

    return addBalance(signer: tx.signer, receipt: tx.receipt);
  }

  Future<String> _callSubmitRaw(PacSubmitRawTransaction rawTx) async {
    log("iap: submit send raw tx to PAC server");
    var tx = rawTx.tx;
    var signer = tx.from;
    var chainId = tx.chainId;
    return submitRawTransaction(signer: signer, chainId: chainId, tx: tx);
  }

  Future<String> _callPurchase(PacPurchaseTransaction tx) async {
    log("iap: submit purchase tx to PAC server");

    // Note: The add balance call should be idempotent, so guarding this
    // Note: is not really necessary.
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

  /*
    get_account
    {'account_id': '0x00A0844371B32aF220548DCE332989404Fda2EeF'}
   */

  /// Get the PAC server USD balance for the account
  Future<USD> getBalance({
    @required EthereumAddress signer,
    PacApiConfig apiConfig, // optional override
  }) async {
    var params = {'account_id': signer.toString(prefix: true)};
    var result = await postJson(
        method: 'get_account', params: params, apiConfig: apiConfig);
    print("XXX: get balance result = $result");
    return USD(0);
  }

  /*
      payment_apple
      {'receipt': 'MIIT0wYJ..', 'account_id': '0x00A0844371B32aF220548DCE332989404Fda2EeF'}
   */
  Future<String> addBalance({
    @required EthereumAddress signer,
    @required String receipt,
    PacApiConfig apiConfig, // optional override
  }) async {
    var params = {
      'account_id': signer.toString(prefix: true),
      'receipt': receipt,
    };
    var result = await postJson(
        method: 'payment_apple', params: params, apiConfig: apiConfig);
    print("XXX: add balance result = " + result.toString());
    return result.toString();
  }

  /*
    send_raw
    {
      "account_id": "0x00A0844371B32aF220548DCE332989404Fda2EeF",
      "chainId": 100,
      "txn": {
        "from": "0x00A0844371B32aF220548DCE332989404Fda2EeF",
        "to": "0xA67D6eCAaE2c0073049BB230FB4A8a187E88B77b",
        "gas": "0x2ab98", // 175k
        "gasPrice": "0x3b9aca00", // 1e9
        "value": "0xde0b6b3a7640000", // 1e18
        "chainId": 100,
        "data": "0x987ff31c00000..."
      }
    }
   */
  Future<String> submitRawTransaction({
    @required EthereumAddress signer,
    @required int chainId,
    @required EthereumTransaction tx,
    PacApiConfig apiConfig, // optional override
  }) async {
    var params = {
      'account_id': signer.toString(prefix: true),
      'chainId': chainId,
      'txn': tx.toJson(),
    };
    print("XXX: send raw json = ${jsonEncode(params)}");
    var result = await postJson(
        method: 'send_raw', params: params, apiConfig: apiConfig);
    print("XXX: send raw result = " + result.toString());
    return result.toString();
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

  /// Post json to our PAC server
  Future<dynamic> postJson({
    @required String method,
    Map<String, dynamic> params = const {},
    PacApiConfig apiConfig, // optional override
  }) async {
    return _postJson(method: method, inParams: params, apiConfig: apiConfig);
  }

  Future<dynamic> _postJson({
    @required String method,
    Map<String, dynamic> inParams = const {},
    PacApiConfig apiConfig, // optional override
  }) async {
    apiConfig = apiConfig ?? await OrchidPurchaseAPI().apiConfig();
    var url = '${apiConfig.url}/$method';

    Map<String, dynamic> params = {};
    params.addAll(inParams);

    // Optional dev testing params
    if (!apiConfig.verifyReceipt) {
      params.addAll({'verify_receipt': 'False'});
    }
    if (apiConfig.debug) {
      params.addAll({'debug': 'True'});
    }

    // Do the post
    var postBody = jsonEncode(params);
    log("iap: posting to $url, json = $postBody");
    var response = await http.post(url,
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: postBody);

    // Validate the response status and content
    log("iap: pac server response: ${response.statusCode}, ${response.body}");
    if (response.statusCode != 200) {
      throw Exception(
          "Error response: code=${response.statusCode} body=${response.body}");
    }
    return json.decode(response.body);
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
