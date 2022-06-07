import 'dart:convert';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/orchid_eth/orchid_account.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../orchid_eth/orchid_chain_config.dart';
import '../orchid_log_api.dart';
import 'accounts_preferences.dart';
import 'chain_config_preferences.dart';
import 'dapp_transaction.dart';

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
    var allKeys = ((await keys.get()) ?? []) + [key];
    return await keys.set(allKeys);
  }

  /// Remove a key from the user's keystore.
  Future<bool> removeKey(StoredEthereumKeyRef keyRef) async {
    var keysList = ((await keys.get()) ?? []);
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
    var allKeys = ((await keys.get()) ?? []) + newKeys;
    return await keys.set(allKeys);
  }

  ///
  /// End: Keys
  ///

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

  /// Add (set-wise) to the distinct set of discovered accounts.
  Future<void> addCachedDiscoveredAccounts(List<Account> accounts) async {
    if (accounts == null || accounts.isEmpty) {
      return;
    }
    var cached = await cachedDiscoveredAccounts.get();
    cached.addAll(accounts);
    cachedDiscoveredAccounts.set(cached);
  }

  /// A set of accounts previously discovered for user identities
  ObservablePreference<Set<Account>> cachedDiscoveredAccounts =
      ObservableAccountSetPreference(
          UserPreferenceKey.CachedDiscoveredAccounts);

  ///
  /// Begin: dapp transactions
  ///

  /// Tracked user dapp transactions
  ObservablePreference<List<DappTransaction>> transactions =
      ObservablePreference(
          key: UserPreferenceKey.Transactions,
          getValue: (key) {
            return _getTransactions();
          },
          putValue: (key, List<DappTransaction> txs) {
            return _setTransactions(txs);
          });

  void addTransaction(DappTransaction tx) {
    transactions.set(transactions.get() + [tx]);
  }

  void addTransactions(Iterable<DappTransaction> txs) {
    transactions.set(transactions.get() + txs.toList());
  }

  void removeTransaction(String txHash) {
    var list = transactions.get();
    list.removeWhere((tx) => tx.transactionHash == txHash);
    transactions.set(list);
  }

  static List<DappTransaction> _getTransactions() {
    String value =
        UserPreferences().getStringForKey(UserPreferenceKey.Transactions);
    if (value == null) {
      return [];
    }
    try {
      var jsonList = jsonDecode(value) as List<dynamic>;
      return jsonList.map((el) {
        return DappTransaction.fromJson(el);
      }).toList();
    } catch (err) {
      log("Error retrieving txs!: $err");
      return [];
    }
  }

  static Future<bool> _setTransactions(Iterable<DappTransaction> txs) async {
    print("XXX setTxs: storing txs: ${jsonEncode(txs.toList())}");
    try {
      var value = jsonEncode(txs.toList());
      return await UserPreferences()
          .putStringForKey(UserPreferenceKey.Transactions, value);
    } catch (err) {
      log("Error storing txs!: $err");
      return false;
    }
  }

  ///
  /// End: dapp transactions
  ///

  /// Identicons UI
  ObservableBoolPreference useBlockiesIdenticons = ObservableBoolPreference(
      UserPreferenceKey.UseBlockiesIdenticons,
      defaultValue: false);

  /// User selected locale override (e.g. en, pt_BR)
  ObservableStringPreference languageOverride =
      ObservableStringPreference(UserPreferenceKey.LanguageOverride);

  // TODO: This is not really applicable in the dapp context.
  /// User Chain config overrides
  ObservableChainConfigPreference chainConfig =
      ObservableChainConfigPreference(UserPreferenceKey.ChainConfig);

  // TODO: This is not really applicable in the dapp context.
  ChainConfig chainConfigFor(int chainId) {
    return ChainConfig.map(chainConfig.get())[chainId];
  }
}

// TODO: Remove unneeded items.
enum UserPreferenceKey {
  UserConfig,
  Keys,
  CachedDiscoveredAccounts,
  Transactions,
  UseBlockiesIdenticons,
  LanguageOverride,
  ChainConfig,
}
