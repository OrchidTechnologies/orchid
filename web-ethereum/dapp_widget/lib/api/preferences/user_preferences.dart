import 'dart:convert';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../orchid_eth/orchid_chain_config.dart';
import '../orchid_log_api.dart';
import 'chain_config_preferences.dart';

class UserPreferences {
  static final UserPreferences _singleton = UserPreferences._internal();

  UserPreferences._internal();

  factory UserPreferences() {
    return _singleton;
  }

  /// The shared instance, initialized by init()
  SharedPreferences _sharedPreferences;

  /// This must be awaited in main before launching the app.
  static Future<void> init() async {
    return UserPreferences()._initInstance();
  }

  Future<void> _initInstance() async {
    log("Initialized user preferences API");
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  bool get initialized {
    return _sharedPreferences != null;
  }

  SharedPreferences sharedPreferences() {
    if (!initialized) {
      throw Exception("UserPreferences uninitialized.");
    }
    return _sharedPreferences;
  }

  String getStringForKey(UserPreferenceKey key) {
    return sharedPreferences().getString(key.toString());
  }

  // This method maps null to property removal.
  Future<bool> putStringForKey(UserPreferenceKey key, String value) async {
    var shared = sharedPreferences();
    if (value == null) {
      return await shared.remove(key.toString());
    }
    return await shared.setString(key.toString(), value);
  }

  /// The user-editable portion of the configuration file text.
  ObservableStringPreference userConfig =
      ObservableStringPreference(UserPreferenceKey.UserConfig);

  // TODO: Remove ad-hoc dependencies on this...
  /// Return the user's keys or [] empty array if uninitialized.
  ObservablePreference<List<StoredEthereumKey>> keys = ObservablePreference(
      key: UserPreferenceKey.Keys,
      getValue: (key) {
        throw Exception("no keys");
      },
      putValue: (key, keys) {
        throw Exception("no keys");
      });

  // Get the user editable configuration file text.
  Future<String> getUserConfig() async {
    return (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.UserConfig.toString());
  }

  // Set the user editable configuration file text.
  Future<bool> setUserConfig(String value) async {
    return (await SharedPreferences.getInstance())
        .setString(UserPreferenceKey.UserConfig.toString(), value);
  }

  /// User selected locale override (e.g. en, pt_BR)
  ObservableStringPreference languageOverride =
      ObservableStringPreference(UserPreferenceKey.LanguageOverride);

  // TODO: This is not really applicable in the web context.
  /// User Chain config overrides
  ObservableChainConfigPreference chainConfig =
      ObservableChainConfigPreference(UserPreferenceKey.ChainConfig);

  // TODO: This is not really applicable in the web context.
  ChainConfig chainConfigFor(int chainId) {
    return ChainConfig.map(chainConfig.get())[chainId];
  }
}

// TODO: Remove unneeded items.
enum UserPreferenceKey {
  UserConfig,
  Keys,
  ActiveAccounts,
  CachedDiscoveredAccounts,
  Transactions,
  LanguageOverride,
  ChainConfig,
}
