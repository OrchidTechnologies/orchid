import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:orchid/api/configuration/orchid_user_config/orchid_user_config.dart';
import 'package:orchid/api/orchid_eth/abi_encode.dart';
import 'package:orchid/api/orchid_eth/eth_transaction.dart';
import 'package:orchid/api/orchid_eth/token_type.dart';
import 'package:orchid/util/json.dart';
import 'package:orchid/util/units.dart';
import 'package:web3dart/crypto.dart';
import '../orchid_api.dart';
import '../orchid_crypto.dart';
import '../orchid_log_api.dart';
import '../orchid_platform.dart';
import 'orchid_pac_seller.dart';
import 'orchid_pac_transaction.dart';
import 'orchid_purchase.dart';
import 'package:orchid/util/strings.dart';
import 'package:convert/convert.dart';

/// The PAC service exchanges an in-app purchase receipt for an Orchid PAC.
class OrchidPACServer {
  static final OrchidPACServer _shared = OrchidPACServer._internal();

  factory OrchidPACServer() {
    return _shared;
  }

  OrchidPACServer._internal();

  /// Apply the receipt to any pending pac receipt transaction and advance it.
  Future<void> advancePACTransactionsWithReceipt(
      String receiptIn, ReceiptType receiptType) async {
    log("iap: advance transaction with receipt.");

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
      await tx.addReceipt(receipt, receiptType).save();
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
        log("iap: timed retry");
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
        case PacTransactionType.SubmitSellerTransaction:
          response = await _callSubmitSellerTx(tx);
          break;
        case PacTransactionType.PurchaseTransaction:
          response = await _callPurchase(tx);
          break;
      }

      // Success: store the response.
      tx.serverResponse = response;
      tx.state = PacTransactionState.Complete;
    } catch (err, stack) {
      // Server error
      log("iap: error in pac submit: $err, $stack");
      tx.serverResponse = "Client side error: $err";

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

    return addBalance(
        signer: tx.signer,
        productId: tx.productId,
        receipt: tx.receipt,
        receiptType: tx.receiptType);
  }

  Future<String> _callSubmitSellerTx(
      PacSubmitSellerTransaction sellerTx) async {
    log("iap: submit seller tx to PAC server: ${sellerTx.toJson()}");
    var tx = sellerTx.txParams;
    print("iap: tx = $tx, tx.chainId = ${tx.chainId}");
    var chainId = tx.chainId;
    var chain = Chains.chainFor(chainId);
    var signerKey = await sellerTx.signerKey.get();
    var signer = signerKey.address;

    var l2Nonce = (await getPacAccount(signer: signer)).nonces[tx.chainId];
    var l3Nonce =
        await OrchidPacSeller.getL3Nonce(chain: chain, signer: signer);

    return submitSellerTransaction(
      signerKey: await sellerTx.signerKey.get(),
      chainId: chainId,
      txParams: tx,
      l2Nonce: l2Nonce,
      l3Nonce: l3Nonce,
      escrowParam: sellerTx.escrow,
    );
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

    // If we are retrying a one-shot purchase refresh the transaction params
    // (account for gas price or calculation changes, etc.)
    /*
    if (tx.retries > 0) {
      var fundingTx = await OrchidPacSeller.defaultFundingTransactionParams(
          signerKey: await tx.submitRaw.signerKey.get(),
          chain: Chains.xDAI,
          totalUsdValue: tx.submitRaw. purchase.usdPriceExact);
    }
    */
    tx.submitRaw.serverResponse = await _callSubmitSellerTx(tx.submitRaw);
    tx.submitRaw.state = PacTransactionState.Complete;

    return [tx.addBalance.serverResponse, tx.submitRaw.serverResponse]
        .toString();
  }

  /*
    get_account
    {'account_id': '0x00A0844371B32aF220548DCE332989404Fda2EeF'}
   */

  /// Get the PAC server USD balance for the account
  Future<PacAccount> getPacAccount({
    @required EthereumAddress signer,
    PacApiConfig apiConfig, // optional override
  }) async {
    var params = {'account_id': signer.toString(prefix: true)};
    var result = await _postJson(
        method: 'get_account', paramsIn: params, apiConfig: apiConfig);
    return PacAccount.fromJson(result);
  }

  /*
      payment_apple
      {'receipt': 'MIIT0wYJ..', 'account_id': '0x00A0844371B32aF220548DCE332989404Fda2EeF'}
   */
  Future<String> addBalance({
    @required EthereumAddress signer,
    @required String productId,
    @required String receipt,
    @required ReceiptType receiptType,
    PacApiConfig apiConfig, // optional override
  }) async {
    var params = {
      'account_id': signer.toString(prefix: true),
      'product_id': productId,
      'receipt': receipt,
    };
    String method;
    switch (receiptType) {
      case ReceiptType.ios:
        method = 'payment_apple';
        break;
      case ReceiptType.android:
        method = 'payment_google';
        break;
    }
    log('pac_server: sending payment to method: $method');
    var result =
        await _postJson(method: method, paramsIn: params, apiConfig: apiConfig);
    print("pac_server: add balance result = " + result.toString());
    return result.toString();
  }

  Future<String> submitSellerTransaction({
    @required StoredEthereumKey signerKey,
    @required int chainId,
    @required int l2Nonce,
    @required int l3Nonce,
    @required EthereumTransactionParams txParams,

    // This is required here in order to sign the edit parameters (inner signature).
    // The corresponding balance is inferred from the tx total value.
    @required BigInt escrowParam,

    // optional override supports testing
    PacApiConfig apiConfig,
  }) async {
    log("iap: submit seller transaction with key and params");

    var adjust = escrowParam;
    var editTx = OrchidPacSeller.sellerEditTransaction(
      signerKey: signerKey,
      params: txParams,
      l2Nonce: l2Nonce,
      l3Nonce: l3Nonce,
      adjust: adjust,
    );

    var txString =
        PacSubmitSellerTransaction.encodePacTransactionString(editTx.toJson());

    var txStringSig =
        OrchidPacSeller.signTransactionString(txString, signerKey);

    var rsv = hex.decode(AbiEncode.uint256(txStringSig.r)) +
        hex.decode(AbiEncode.uint256(txStringSig.s)) +
        intToBytes(BigInt.from(txStringSig.v));

    var params = {
      'account_id': signerKey.address.toString(prefix: true),
      'chainId': chainId,
      // txn is encoded as an escaped json string
      'txn': txString,
      'sig': '0x' + hex.encode(rsv)
    };

    // print("iap: seller tx: send raw json = ${jsonEncode(params)}");
    var result = await _postJson(
        method: 'send_raw', paramsIn: params, apiConfig: apiConfig);
    // print("iap: seller tx: send raw result = " + result.toString());

    return result.toString();
  }

  /// V1 pac store status.  This method returns down in the event of error.
  Future<PACStoreStatus> storeStatus() async {
    log("iap: check PAC server status");

    bool overrideDown = (await OrchidUserConfig().getUserConfigJS())
        .evalBoolDefault('pacs.storeDown', false);
    if (overrideDown) {
      log("iap: override server status");
      return PACStoreStatus.down;
    }

    // Do the post
    var responseJson;
    try {
      responseJson = await _postJson(method: "store_status", paramsIn: {});
    } catch (err, stack) {
      log("iap: pac server status response error: $err, $stack");
      return PACStoreStatus.down;
    }

    // parse store status
    var storeStatus =
        Json.toIntSafe(responseJson['store_status'], defaultValue: 0);

    // parse store message
    var jsonMessage = Json.trimStringOrNull(responseJson['message']);
    String message = (await OrchidUserConfig().getUserConfigJS())
        .evalStringDefault('pacs.storeMessage', jsonMessage);

    // parse the seller address map
    // TODO: ...

    // Testing...
    // message = "Testing store message...";
    // return PACStoreStatus.down;

    return PACStoreStatus(open: storeStatus == 1, message: message);
  }

  /// Post json to our PAC server
  Future<dynamic> _postJson({
    @required String method,
    @required Map<String, dynamic> paramsIn,
    PacApiConfig apiConfig, // optional override
  }) async {
    apiConfig = apiConfig ?? await OrchidPurchaseAPI().apiConfig();
    var url = '${apiConfig.url}/$method';

    // Guard the unknown map type
    var params = Map<String, dynamic>();
    params.addAll(paramsIn);

    // Optional dev testing params
    if (!apiConfig.verifyReceipt) {
      params.addAll({'verify_receipt': 'False'});
    }
    if (apiConfig.debug) {
      params.addAll({'debug': 'True'});
    }

    return _postJsonToUrl(url: url, paramsIn: params);
  }

  /// Post json to our PAC server
  Future<dynamic> _postJsonToUrl({
    @required String url,
    @required Map<String, dynamic> paramsIn,
  }) async {
    var clientVersion = await OrchidAPI().versionString();
    var clientLocale = OrchidPlatform.staticLocale.toLanguageTag();

    // Guard the unknown map type
    var params = Map<String, dynamic>();
    params.addAll(paramsIn);

    // Version and locale
    params.addAll({
      // client locale is in the accept headers
      'client_platform': OrchidPlatform.operatingSystem,
      'client_version': clientVersion,
    });

    // Do the http post
    var postBody = jsonEncode(params);
    logWrapped("iap: posting to $url, json = $postBody");
    var response = await http.post(url,
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Accept-Language": clientLocale,
        },
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
  static PACStoreStatus down = PACStoreStatus(
      open: false, message: "The store is temporarily unavailable.");

  // overall store status
  final bool open;

  // Message to display or null if none.
  final String message;

  // product status
  //Map<String, bool> product;

  PACStoreStatus({this.message, this.open});
}

class PacAccount {
  USD balance;
  Map<int, int> nonces;

  // get balance result = {account_id: 0x92cFa426Cb13Df5151aD1eC8865c5C6841546603,
  //  nonces: {100: 3}, balance: 156.955389285125}
  PacAccount.fromJson(Map<String, dynamic> json) {
    this.balance = USD(Json.toDouble(json['balance']));
    var nonceJson = json['nonces'];
    nonces = {
      // for (var key in nonceJson.keys) int.parse(key): int.parse(nonceJson[key])
      for (var key in nonceJson.keys)
        Json.toInt(key): Json.toInt(nonceJson[key])
    };
  }

  @override
  String toString() {
    return 'PacAccount{balance: $balance, nonces: $nonces}';
  }
}
