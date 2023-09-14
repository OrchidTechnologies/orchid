import 'dart:convert';
import 'package:orchid/api/orchid_log.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/preferences/user_preferences.dart';

// Holds a list of accounts. Returns [] empty list initially.
class ObservableAccountListPreference
    extends ObservablePreference<List<Account>> {
  ObservableAccountListPreference(UserPreferenceKey key)
      : super(
            key: key,
            getValue: (key) {
              String? value = UserPreferences().getStringForKey(key);
              try {
                return fromJson(value);
              } catch (err) {
                log("Error retrieving accounts for $key!: $err");
                return [];
              }
            },
            putValue: (key, accounts) {
              if (accounts == null) {
                return UserPreferences().putStringForKey(key, null);
              } else {
                String value = toJson(accounts);
                return UserPreferences().putStringForKey(key, value);
              }
            });

  static List<Account> fromJson(String? value) {
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
        .whereType<Account>()
        .toList();
  }

  static toJson(List<Account> accounts) {
    return accounts != null ? jsonEncode(accounts) : null;
  }
}

// Holds a set of accounts. Returns {} empty set initially.
// Writes {} empty set on null;
class ObservableAccountSetPreference
    extends ObservablePreference<Set<Account>> {
  ObservableAccountSetPreference(UserPreferenceKey key)
      : super(
            key: key,
            getValue: (key) {
              String? value = UserPreferences().getStringForKey(key);
              try {
                return Set.from(
                    ObservableAccountListPreference.fromJson(value));
              } catch (err) {
                log("Error retrieving accounts for $key!: $err");
                return {};
              }
            },
            putValue: (key, accounts) async {
              String value = ObservableAccountListPreference.toJson(
                  (accounts ?? {}).toList());
              return UserPreferences().putStringForKey(key, value);
            });
}
