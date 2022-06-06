import 'dart:convert';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/orchid_eth/orchid_chain_config.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:orchid/api/preferences/user_preferences_mock.dart';
import 'package:orchid/api/purchase/orchid_pac_transaction.dart';
import 'package:orchid/api/orchid_eth/orchid_account_mock.dart';
import 'package:orchid/pages/circuit/model/circuit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../orchid_log_api.dart';
import 'accounts_preferences.dart';
import 'chain_config_preferences.dart';

class UserPreferences {
  static final UserPreferences _singleton = UserPreferences._internal();

  factory UserPreferences() {
    return _singleton;
  }

  UserPreferences._internal();

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

  ///
  /// Begin: Circuit
  ///

  ObservablePreference<Circuit> circuit = ObservablePreference(
      key: UserPreferenceKey.Circuit,
      getValue: (key) {
        return _getCircuit();
      },
      putValue: (key, circuit) {
        return _setCircuit(circuit);
      });

  // Set the circuit / hops configuration
  static Future<bool> _setCircuit(Circuit circuit) async {
    String value = circuit != null ? jsonEncode(circuit) : null;
    return UserPreferences().putStringForKey(UserPreferenceKey.Circuit, value);
  }

  // Get the circuit / hops configuration
  // This default to an empty [] circuit if uninitialized.
  static Circuit _getCircuit() {
    if (AccountMock.mockAccounts) {
      return UserPreferencesMock.mockCircuit;
    }
    String value = UserPreferences().getStringForKey(UserPreferenceKey.Circuit);
    return value == null ? Circuit([]) : Circuit.fromJson(jsonDecode(value));
  }

  ///
  /// End: Circuit
  ///

  /// The user-editable portion of the configuration file text.
  ObservableStringPreference userConfig =
      ObservableStringPreference(UserPreferenceKey.UserConfig);

  ///
  /// Begin: Keys
  ///

  /// Return the user's keys or [] empty array if uninitialized.
  ObservablePreference<List<StoredEthereumKey>> keys = ObservablePreference(
      key: UserPreferenceKey.Keys,
      getValue: (key) {
        return _getKeys();
      },
      putValue: (key, keys) {
        return _setKeys(keys);
      });

  /// Return the user's keys or [] empty array if uninitialized.
  static List<StoredEthereumKey> _getKeys() {
    if (AccountMock.mockAccounts) {
      return AccountMock.mockKeys;
    }

    String value = UserPreferences().getStringForKey(UserPreferenceKey.Keys);
    if (value == null) {
      return [];
    }
    try {
      var jsonList = jsonDecode(value) as List<dynamic>;
      return jsonList
          .map((el) {
            try {
              return StoredEthereumKey.fromJson(el);
            } catch (err) {
              log("Error decoding key: $err");
              return null;
            }
          })
          .where((key) => key != null)
          .toList();
    } catch (err) {
      log("Error retrieving keys!: $err");
      return [];
    }
  }

  static Future<bool> _setKeys(List<StoredEthereumKey> keys) async {
    print("setKeys: storing keys: ${jsonEncode(keys)}");
    try {
      var value = jsonEncode(keys);
      return await UserPreferences()
          .putStringForKey(UserPreferenceKey.Keys, value);
    } catch (err) {
      log("Error storing keys!: $err");
      return false;
    }
  }

  /// Add a key to the user's keystore.
  // Note: Minimizes exposure to the full setKeys()
  Future<void> addKey(StoredEthereumKey key) async {
    var allKeys = ((keys.get()) ?? []) + [key];
    return await keys.set(allKeys);
  }

  /// Remove a key from the user's keystore.
  Future<bool> removeKey(StoredEthereumKeyRef keyRef) async {
    var keysList = ((keys.get()) ?? []);
    try {
      keysList.removeWhere((key) => key.uid == keyRef.keyUid);
    } catch (err) {
      log("account: error removing key: $keyRef");
      return false;
    }
    await keys.set(keysList);
    return true;
  }

  /// Add a list of keys to the user's keystore.
  Future<void> addKeys(List<StoredEthereumKey> newKeys) async {
    var allKeys = ((keys.get()) ?? []) + newKeys;
    return await keys.set(allKeys);
  }

  ///
  /// End: Keys
  ///

  String getDefaultCurator() {
    return getStringForKey(UserPreferenceKey.DefaultCurator);
  }

  Future<bool> setDefaultCurator(String value) async {
    return putStringForKey(UserPreferenceKey.DefaultCurator, value);
  }

  bool getQueryBalances() {
    return sharedPreferences()
            .getBool(UserPreferenceKey.QueryBalances.toString()) ??
        true;
  }

  Future<bool> setQueryBalances(bool value) async {
    return sharedPreferences()
        .setBool(UserPreferenceKey.QueryBalances.toString(), value);
  }

  /// The PAC transaction or null if there is none.
  ObservablePreference<PacTransaction> pacTransaction = ObservablePreference(
      key: UserPreferenceKey.PacTransaction,
      getValue: (key) {
        String value = UserPreferences().getStringForKey(key);
        try {
          return value != null
              ? PacTransaction.fromJson(jsonDecode(value))
              : null;
        } catch (err) {
          log("pacs: Unable to decode v1 transaction, returning null: $value, $err");
          return null;
        }
      },
      putValue: (key, tx) {
        String value = tx != null ? jsonEncode(tx) : null;
        return UserPreferences().putStringForKey(key, value);
      });

  // TODO: Currently maintained only for use in migration to new circuit builder.
  /// A list of account information indicating the active identity (signer key)
  /// and the active account (funder and chainid) for that identity.
  /// The order of this list is significant in that the first account designates
  /// the active identity for routing.  The remaining items in the list serve
  /// as a history of previous account selections for the respective identities.
  /// Identities should appear in this list only once.
  /// @See Account.activeAccount
  ObservablePreference<List<Account>> activeAccounts =
      ObservableAccountListPreference(UserPreferenceKey.ActiveAccounts);

  /// Add (set-wise) to the distinct set of discovered accounts.
  Future<void> addCachedDiscoveredAccounts(List<Account> accounts) async {
    if (accounts == null || accounts.isEmpty) {
      return;
    }
    if (accounts.contains(null)) {
      throw Exception('null account in add to cache');
    }
    var cached = cachedDiscoveredAccounts.get();
    cached.addAll(accounts);
    return cachedDiscoveredAccounts.set(cached);
  }

  /// A set of accounts previously discovered for user identities
  /// Returns {} empty set initially.
  ObservablePreference<Set<Account>> cachedDiscoveredAccounts =
      ObservableAccountSetPreference(
          UserPreferenceKey.CachedDiscoveredAccounts);

  /// An incrementing internal UI app release notes version used to track
  /// new release messaging.  See class [Release]
  ObservablePreference<ReleaseVersion> releaseVersion = ObservablePreference(
      key: UserPreferenceKey.ReleaseVersion,
      getValue: (key) {
        return ReleaseVersion(
            (UserPreferences().sharedPreferences()).getInt(key.toString()));
      },
      putValue: (key, value) async {
        var sharedPreferences = UserPreferences().sharedPreferences();
        if (value.version == null) {
          return sharedPreferences.remove(key.toString());
        }
        return sharedPreferences.setInt(key.toString(), value.version);
      });

  /// User preference indicating that the VPN should be enabled to route traffic
  /// per the user's hop configuration.
  /// Note that the actual state of the VPN subsystem is controlled by the OrchidAPI
  /// and may also take into account the monitoring preference.
  ObservableBoolPreference routingEnabled = ObservableBoolPreference(
      UserPreferenceKey.RoutingEnabled,
      defaultValue: false);

  /// User preference indicating that the Orchid VPN should be enabled to monitor traffic.
  /// Note that the actual state of the VPN subsystem is controlled by the OrchidAPI
  /// and may also take into account the vpn enabled preference.
  ObservableBoolPreference monitoringEnabled = ObservableBoolPreference(
      UserPreferenceKey.MonitoringEnabled,
      defaultValue: false);

  /// User locale override (e.g. en, pt_BR)
  ObservableStringPreference languageOverride =
      ObservableStringPreference(UserPreferenceKey.LanguageOverride);

  /// User Chain config overrides
  ObservableChainConfigPreference chainConfig =
      ObservableChainConfigPreference(UserPreferenceKey.ChainConfig);

  ChainConfig chainConfigFor(int chainId) {
    return ChainConfig.map(chainConfig.get())[chainId];
  }
}

enum UserPreferenceKey {
  Circuit,
  UserConfig,
  Keys,
  DefaultCurator,
  QueryBalances,
  PacTransaction,
  ActiveAccounts,
  CachedDiscoveredAccounts,
  ReleaseVersion,
  RoutingEnabled,
  MonitoringEnabled,
  LanguageOverride,
  ChainConfig
}
