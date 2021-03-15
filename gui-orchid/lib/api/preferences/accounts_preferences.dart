import 'dart:convert';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import '../orchid_log_api.dart';

// Holds a list of accounts. Returns [] empty list initially.
class ObservableAccountListPreference
    extends ObservablePreference<List<Account>> {
  ObservableAccountListPreference(UserPreferenceKey key)
      : super(
            key: key,
            loadValue: (key) async {
              String value = await UserPreferences.readStringForKey(key);
              try {
                return fromJson(value);
              } catch (err) {
                log("Error retrieving accounts for $key!: $err");
                return [];
              }
            },
            storeValue: (key, accounts) {
              String value = toJson(accounts);
              return UserPreferences.writeStringForKey(key, value);
            });

  static List<Account> fromJson(String value) {
    if (value == null) {
      return [];
    }
    var jsonList = jsonDecode(value) as List<dynamic>;
    return jsonList
        .map((el) {
          try {
            return Account.fromJson(el);
          } catch (err) {
            log("Error decoding account: $err");
            return null;
          }
        })
        .where((account) => account != null)
        .toList();
  }

  static toJson(List<Account> accounts) {
    return accounts != null ? jsonEncode(accounts) : null;
  }
}

// Holds a set of accounts. Returns {} empty set initially.
class ObservableAccountSetPreference
    extends ObservablePreference<Set<Account>> {
  ObservableAccountSetPreference(UserPreferenceKey key)
      : super(
            key: key,
            loadValue: (key) async {
              String value = await UserPreferences.readStringForKey(key);
              try {
                return Set.from(
                    ObservableAccountListPreference.fromJson(value));
              } catch (err) {
                log("Error retrieving accounts for $key!: $err");
                return {};
              }
            },
            storeValue: (key, accounts) {
              String value =
                  ObservableAccountListPreference.toJson(accounts.toList());
              return UserPreferences.writeStringForKey(key, value);
            });
}
