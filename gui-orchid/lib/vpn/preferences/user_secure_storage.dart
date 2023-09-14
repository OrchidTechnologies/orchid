import 'dart:convert';

// TODO: Stand-in this until we have support for MacOS
//import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:orchid/vpn/purchase/purchase_rate.dart';
import '../../api/orchid_log.dart';

// TODO: Stand-in until we have support for MacOS
class NonSecureStorage {
  Future<String?> read({required String key}) async {
    return (UserPreferences().sharedPreferences()).getString(key.toString());
  }

  // This method accepts null for property removal.
  Future<void> write({required String key, String? value}) async {
    var shared = UserPreferences().sharedPreferences();
    if (value == null) {
      await shared.remove(key);
    }
    await shared.setString(key, value!);
  }
}

class UserSecureStorage {
  static final UserSecureStorage _singleton = UserSecureStorage._internal();

  factory UserSecureStorage() {
    return _singleton;
  }

  UserSecureStorage._internal() {
    log("constructed secure storage API");
  }

  Future<PurchaseRateHistory> getPurchaseRateHistory() async {
    // TODO: Stand-in until we have support for MacOS
    //final storage = FlutterSecureStorage();
    final storage = NonSecureStorage();
    var str = await storage.read(
        key: UserSecureStorageKey.PACPurchaseRateHistory.toString());
    if (str == null) {
      log("iap: No pac history, defaulting.");
    } else {
      try {
        return PurchaseRateHistory.fromJson(jsonDecode(str));
      } catch (err) {
        log("iap: Error reading history, defaulting: $err");
      }
    }
    return PurchaseRateHistory([]);
  }

  Future<void> setPurchaseRateHistory(PurchaseRateHistory history) async {
    log('iap: saving rate history, ${history.purchases.length} items totalling: ${history.sum()}');
    // TODO: Stand-in until we have support for MacOS
    // final storage = FlutterSecureStorage();
    final storage = NonSecureStorage();
    try {
      String json = jsonEncode(history);
      return storage.write(
          key: UserSecureStorageKey.PACPurchaseRateHistory.toString(),
          value: json);
    } catch (err) {
      log("iap: Error saving history: $err");
    }
  }
}

enum UserSecureStorageKey { PACPurchaseRateHistory }
