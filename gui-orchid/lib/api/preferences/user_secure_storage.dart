import 'dart:convert';

// TODO: Stand-in this until we have support for MacOS
//import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:orchid/api/preferences/user_preferences.dart';

import 'package:orchid/api/purchase/purchase_rate.dart';

// TODO: Stand-in until we have support for MacOS
class NonSecureStorage {
  Future<String> read({String key}) async {
    return (await UserPreferences.sharedPreferences())
        .getString(key.toString());
  }

  Future<void> write({String key, String value}) async {
    return await (await UserPreferences.sharedPreferences())
        .setString(key.toString(), value);
  }
}

class UserSecureStorage {
  static final UserSecureStorage _singleton = UserSecureStorage._internal();

  factory UserSecureStorage() {
    return _singleton;
  }

  UserSecureStorage._internal() {
    print("constructed secure storage API");
  }

  Future<PurchaseRateHistory> getPurchaseRateHistory() async {
    // TODO: Stand-in until we have support for MacOS
    //final storage = FlutterSecureStorage();
    final storage = NonSecureStorage();
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
    // TODO: Stand-in until we have support for MacOS
    // final storage = FlutterSecureStorage();
    final storage = NonSecureStorage();
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
