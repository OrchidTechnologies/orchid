import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:orchid/api/purchase/purchase_rate.dart';

class UserSecureStorage {
  static final UserSecureStorage _singleton = UserSecureStorage._internal();

  factory UserSecureStorage() {
    return _singleton;
  }

  UserSecureStorage._internal() {
    print("constructed secure storage API");
  }

  Future<PurchaseRateHistory> getPurchaseRateHistory() async {
    final storage = FlutterSecureStorage();
    var str = await storage.read(
        key: UserSecureStorageKey.PACPurchaseRateHistory.toString());
    if (str == null) {
      print("pac: No pac history, defaulting.");
    } else {
      try {
        return PurchaseRateHistory.fromJson(jsonDecode(str));
      } catch (err) {
        print("pac: Error reading history, defaulting: $err");
      }
    }
    return PurchaseRateHistory([]);
  }

  Future<void> setPurchaseRateHistory(PurchaseRateHistory history) async {
    print(
        "pac: saving rate history, ${history.purchases.length} items totalling: ${history.sum()}");
    final storage = FlutterSecureStorage();
    try {
      String json = jsonEncode(history);
      return storage.write(
          key: UserSecureStorageKey.PACPurchaseRateHistory.toString(),
          value: json);
    } catch (err) {
      print("pac: Error saving history: $err");
    }
  }
}

enum UserSecureStorageKey { PACPurchaseRateHistory }
