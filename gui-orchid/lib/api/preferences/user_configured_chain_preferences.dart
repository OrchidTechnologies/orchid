import 'dart:convert';
import 'package:orchid/api/orchid_eth/chains.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import '../orchid_log.dart';
import 'observable_preference.dart';

class ObservableUserConfiguredChainPreference
    extends ObservablePreference<List<UserConfiguredChain>> {
  ObservableUserConfiguredChainPreference(UserPreferenceKey key)
      : super(
            key: key,
            getValue: (key) {
              try {
                final value = UserPreferences().getStringForKey(key);
                if (value == null) {
                  return [];
                }
                final jsonList = jsonDecode(value) as List<dynamic>;
                List<UserConfiguredChain> list = jsonList.map((el) {
                  return UserConfiguredChain.fromJson(el);
                }).toList();
                return list;
              } catch (err) {
                log("Error reading preference: $key, $err");
                return [];
              }
            },
            putValue: (key, List<UserConfiguredChain>? list) async {
              if (list == null) {
                return UserPreferences().putStringForKey(key, null);
              }
              try {
                final json = jsonEncode(list);
                return UserPreferences().putStringForKey(key, json);
              } catch (err) {
                log("Error saving preference: $key, $err");
              }
            });

  Future<void> add(UserConfiguredChain chain) async {
    var chains = ((this.get()) ?? []) + [chain];
    await this.set(chains);
  }

  Future<void> remove(UserConfiguredChain chain) async {
    var chains = this.get();
    chains?.remove(chain);
    await this.set(chains);
  }
}
