import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:in_app_purchase/store_kit_wrappers.dart';
import 'package:orchid/util/units.dart';
import 'orchid_api.dart';
import 'package:http/http.dart' as http;

class PAC {
  String productId;
  USD usdPurchasePrice;
  String displayName;

  PAC(this.productId, this.usdPurchasePrice, this.displayName);
}

/// Support in-app purchase of purchased access credits (PACs).
abstract class OrchidPurchaseAPI {
  static OrchidPurchaseAPI _shared;

  static int SKErrorPaymentCancelled = 2; // The raw value from the API

  // Feature flag for testing PAC purchases
  static Future<bool> purchaseEnabled() async {
    return (await OrchidAPI().getConfiguration())
        .contains(RegExp(r'pacs *= *[Tt]rue'));
  }

  //static String domain = 'pat';
  //static PAC pacTest = PAC('test_purchase_1', USD(4.99), "\$4.99 USD");
  static String domain = 'orchid';
  static PAC pacTier1 = PAC('net.$domain.US499', USD(4.99), "\$4.99 USD");
  // TODO: product id
  static PAC pacTier2 = PAC('net.$domain.US499', USD(9.99), "\$9.99 USD");
  // TODO: product id
  static PAC pacTier3 = PAC('net.$domain.US499', USD(19.99), "\$19.99 USD");

  OrchidPurchaseAPI._init();

  initStoreListener() {}

  factory OrchidPurchaseAPI() {
    if (_shared == null) {
      if (Platform.isIOS) {
        print("xxx: init ios purchase api");
        _shared = IOSOrchidPurchaseAPI();
      } else if (Platform.isAndroid) {
        _shared = AndroidOrchidPurchaseAPI();
      } else {
        throw Exception("no purchase on platform");
      }
    }
    return _shared;
  }

  void testPurchase();

  /// Make the app store purchase. The future will resolve when the purchase
  /// has been confirmed and return the store receipt which can then be
  /// submitted to the PAC server for delivery.
  Future<String> purchase(PAC pac);

}

class IOSOrchidPurchaseAPI
    implements OrchidPurchaseAPI, SKTransactionObserverWrapper {
  static String test_purchase_1 = "test_purchase_1";

  // Map of product id to a completer for the transaction.
  // As implemented this limits concurrent purchases, which seems ok.
  Map<String, Completer<String>> pendingPurchases = {};

  @override
  initStoreListener() async {
    print("xxx: init store listener");
    try {
      var receiptData = await SKReceiptManager.retrieveReceiptData();
      print("xxx: app receipt: BEGIN:${receiptData.substring(0,32)}:END");
    } catch (err) {
      print("xxx: unable to load app receipt");
    }
    SKPaymentQueueWrapper().setTransactionObserver(this);
    var productIds = [
      //OrchidPurchaseAPI.pacTest.productId,
      OrchidPurchaseAPI.pacTier1.productId,
      OrchidPurchaseAPI.pacTier2.productId,
      OrchidPurchaseAPI.pacTier3.productId
    ];
    SkProductResponseWrapper productResponse =
        await SKRequestMaker().startProductRequest(productIds);
    print("xxx: product response: ${productResponse.products.map((p)=>p.productIdentifier)}");
  }

  @override
  void paymentQueueRestoreCompletedTransactionsFinished() {}

  @override
  void removedTransactions({List<SKPaymentTransactionWrapper> transactions}) {
    print("removed transactions: $transactions");
  }

  @override
  void restoreCompletedTransactionsFailed({SKError error}) {
    print("restore failed");
  }

  @override
  bool shouldAddStorePayment(
      {SKPaymentWrapper payment, SKProductWrapper product}) {
    return true;
  }

  @override
  void updatedTransactions(
      {List<SKPaymentTransactionWrapper> transactions}) async {
    for (var tx in transactions) {
      print("xxx: updated transaction: $tx");
      if(tx.error != null) {
        print("xxx: tx error = ${tx.error.code}, ${tx.error.userInfo}");
      }
      print("xxx: updateTransactions pending purchases: ${pendingPurchases.length}");
      var completion = pendingPurchases[tx.payment.productIdentifier];
      if (tx.transactionState == SKPaymentTransactionStateWrapper.purchased) {
        pendingPurchases.remove(tx.payment.productIdentifier);
        print("xxx: finishing transaction");
        await SKPaymentQueueWrapper().finishTransaction(tx);
        var receiptData = await SKReceiptManager.retrieveReceiptData();
        completion?.complete(receiptData);
      }
      if (tx.transactionState == SKPaymentTransactionStateWrapper.failed) {
        pendingPurchases.remove(tx.payment.productIdentifier);
        print("xxx: finishing error transaction");
        await SKPaymentQueueWrapper().finishTransaction(tx);
        completion?.completeError(tx.error);
      }
    }
  }

  @override
  void testPurchase() {
    var payment = SKPaymentWrapper(productIdentifier: "test_purchase_1");
    SKPaymentQueueWrapper().addPayment(payment);
  }

  Future<String> purchase(PAC pac) async {
    var completion = Completer<String>();
    if (pendingPurchases.containsKey(pac.productId)) {
      throw Exception("already a pending transaction for this product");
    }
    pendingPurchases[pac.productId] = completion;
    var payment = SKPaymentWrapper(productIdentifier: pac.productId);
    await SKPaymentQueueWrapper().addPayment(payment);
    return completion.future;
  }
}

class AndroidOrchidPurchaseAPI implements OrchidPurchaseAPI {
  @override
  initStoreListener() {
    // TODO: implement initStoreListener
    throw UnimplementedError();
  }

  @override
  void testPurchase() {
    // TODO: implement testPurchase
  }

  Future<String> purchase(PAC pac) {
    throw UnimplementedError();
  }
}

class OrchidPACServer {

  /// Submit an app store receipt to the PAC server to receive the pot info.
  static Future<String> submit(String appStoreReceipt) async {

    var url='https://sbdds4zh8a.execute-api.us-west-2.amazonaws.com/dev/submit';

    var verifyReceipt='False';

    var logPostBody = '{'
        '"receipt": "${appStoreReceipt.substring(0,32)}...",'
        '"verify_receipt": "$verifyReceipt",'
        '"total_usd": "10"'
        '}';
    print("xxx: log post body = $logPostBody");

    // TODO: Get rid of total_usd field!
    var postBody = '{'
        '"receipt": "$appStoreReceipt",'
        '"verify_receipt": "$verifyReceipt",'
        '"total_usd": "10"'
        '}';

    // do the post
    var response = await http.post(url,
        headers: {"Content-Type": "application/json; charset=utf-8"}, body: postBody);

    print("xxx: pac server response: ${response.statusCode}, ${response.body}");
    if (response.statusCode != 200) {
      throw Exception("Error status code: ${response.statusCode}");
    }
    return response.body;
  }
}
