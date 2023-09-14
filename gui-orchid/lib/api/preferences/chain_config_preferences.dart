import 'dart:convert';
import 'package:orchid/api/orchid_eth/orchid_chain_config.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import '../orchid_log.dart';
import 'observable_preference.dart';

class ObservableChainConfigPreference
    extends ObservablePreference<List<ChainConfig>> {
  ObservableChainConfigPreference(UserPreferenceKey key)
      : super(
            key: key,
            getValue: (key) {
              try {
                final value = UserPreferences().getStringForKey(key);
                if (value == null) {
                  return [];
                }
                final jsonList = jsonDecode(value) as List<dynamic>;
                List<ChainConfig> list = jsonList.map((el) {
                  return ChainConfig.fromJson(el);
                }).toList();
                return list;
              } catch (err) {
                log("Error reading preference: $key, $err");
                return [];
              }
            },
            putValue: (key, List<ChainConfig>? list) async {
              try {
                final json = jsonEncode(list);
                return UserPreferences().putStringForKey(key, json);
              } catch (err) {
                log("Error saving preference: $key, $err");
              }
            });
}
