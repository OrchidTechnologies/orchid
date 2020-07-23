import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_crypto.dart';
import 'package:orchid/api/preferences/observable_preference.dart';
import 'package:orchid/api/purchase/orchid_pac.dart';
import 'package:orchid/pages/circuit/model/circuit.dart';
import 'package:orchid/pages/circuit/model/circuit_hop.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../orchid_api.dart';
import '../orchid_budget_api.dart';
import '../orchid_log_api.dart';

class UserPreferences {
  static final UserPreferences _singleton = UserPreferences._internal();

  factory UserPreferences() {
    return _singleton;
  }

  UserPreferences._internal() {
    debugPrint("constructed user prefs API");
  }

  static Future<SharedPreferences> sharedPreferences() {
    return SharedPreferences.getInstance();
  }

  static Future<String> readStringForKey(UserPreferenceKey key) async {
    return (await sharedPreferences()).getString(key.toString());
  }

  // This method accepts null as equivalent to removing the preference.
  static Future<void> writeStringForKey(
      UserPreferenceKey key, String value) async {
    return await (await sharedPreferences()).setString(key.toString(), value);
  }

  /// Reset all instructional / onboarding / first launch experience
  /// options to their default state.
  void resetInstructions() {
    setVPNSwitchInstructionsViewed(false);
    setFirstLaunchInstructionsViewed(false);
  }

  ///
  /// Onboarding pages related preferences
  /// TODO: Replace these with one StringList?
  ///

  /// Was the user prompted for the necessary permissions to install the VPN
  /// extension as part of onboarding
  Future<bool> getPromptedForVPNPermission() async {
    return (await SharedPreferences.getInstance())
            .getBool(UserPreferenceKey.PromptedForVPNPermission.toString()) ??
        false;
  }

  /// Was the user prompted for the necessary permissions to install the VPN
  /// extension as part of onboarding
  Future<bool> setPromptedForVPNPermission(bool value) async {
    return (await SharedPreferences.getInstance())
        .setBool(UserPreferenceKey.PromptedForVPNPermission.toString(), value);
  }

  Future<bool> setBudget(Budget budget) async {
    String value = jsonEncode(budget);
    print("json = $value");
    return (await SharedPreferences.getInstance())
        .setString(UserPreferenceKey.Budget.toString(), value);
  }

  Future<Budget> getBudget() async {
    String value = (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.Budget.toString());
    if (value == null) {
      return null;
    }
    return Budget.fromJson(jsonDecode(value));
  }

  // Set the circuit / hops configuration
  Future<bool> setCircuit(Circuit circuit) async {
    String value = jsonEncode(circuit);
    return (await SharedPreferences.getInstance())
        .setString(UserPreferenceKey.Circuit.toString(), value);
  }

  // Get the circuit / hops configuration
  Future<Circuit> getCircuit() async {
    String value = (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.Circuit.toString());
    if (value == null) {
      return Circuit([]);
    }
    return Circuit.fromJson(jsonDecode(value));
  }

  // Add a single hop to the recently deleted list
  void addRecentlyDeletedHop(CircuitHop hop) async {
    var hops = await getRecentlyDeleted();
    hops.hops.add(hop);
    await setRecentlyDeleted(hops);
  }

  // Store recently deleted hops
  Future<bool> setRecentlyDeleted(Hops hops) async {
    log("saving recently deleted hops: ${hops.hops}");
    String value = jsonEncode(hops);
    return (await SharedPreferences.getInstance())
        .setString(UserPreferenceKey.RecentlyDeletedHops.toString(), value);
  }

  // Get a list of recently deleted hops.
  Future<Hops> getRecentlyDeleted() async {
    String value = (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.RecentlyDeletedHops.toString());
    if (value == null) {
      return Hops([]);
    }
    return Hops.fromJson(jsonDecode(value));
  }

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

  // Note: A format change or bug that causes a decoding error here would be bad.
  // Note: When we move these keys to secure storage the issues will change
  // Note: so we will rely on this for now.
  Future<List<StoredEthereumKey>> getKeys() async {
    String value = (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.Keys.toString());
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
              OrchidAPI().logger().write("Error decoding key: $err");
              return null;
            }
          })
          .where((key) => key != null)
          .toList();
    } catch (err) {
      OrchidAPI().logger().write("Error retrieving keys!: $err");
      return [];
    }
  }

  Future<bool> setKeys(List<StoredEthereumKey> keys) async {
    print("setKeys: storing keys: ${jsonEncode(keys)}");
    try {
      return (await SharedPreferences.getInstance())
          .setString(UserPreferenceKey.Keys.toString(), jsonEncode(keys));
    } catch (err) {
      OrchidAPI().logger().write("Error storing keys!: $err");
      return false;
    }
  }

  /// Add a key to the user's keystore.
  // Note: Minimizes exposure to the full setKeys()
  Future<bool> addKey(StoredEthereumKey key) async {
    var keys = ((await UserPreferences().getKeys()) ?? []) + [key];
    return UserPreferences().setKeys(keys);
  }

  /// Add a list of keys to the user's keystore.
  // Note: Minimizes exposure to the full setKeys()
  Future<bool> addKeys(List<StoredEthereumKey> newKeys) async {
    var keys = ((await UserPreferences().getKeys()) ?? []) + newKeys;
    return UserPreferences().setKeys(keys);
  }

  Future<String> getDefaultCurator() async {
    return (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.DefaultCurator.toString());
  }

  Future<bool> setDefaultCurator(String value) async {
    return (await SharedPreferences.getInstance())
        .setString(UserPreferenceKey.DefaultCurator.toString(), value);
  }

  Future<bool> getQueryBalances() async {
    return (await SharedPreferences.getInstance())
            .getBool(UserPreferenceKey.QueryBalances.toString()) ??
        true;
  }

  Future<bool> setQueryBalances(bool value) async {
    return (await SharedPreferences.getInstance())
        .setBool(UserPreferenceKey.QueryBalances.toString(), value);
  }

  // Get the user's desired vpn state where true is on, false is off.
  // Defaults to false if never set.
  Future<bool> getDesiredVPNState() async {
    return (await SharedPreferences.getInstance())
            .getBool(UserPreferenceKey.DesiredVPNState.toString()) ??
        false;
  }

  // Set the user's desired vpn state where true is on, false is off.
  Future<bool> setDesiredVPNState(bool value) async {
    return (await SharedPreferences.getInstance())
        .setBool(UserPreferenceKey.DesiredVPNState.toString(), value);
  }

  Future<bool> getShowStatusTab() async {
    return (await SharedPreferences.getInstance())
            .getBool(UserPreferenceKey.ShowStatusTab.toString()) ??
        false;
  }

  Future<bool> setShowStatusTab(bool value) async {
    return (await SharedPreferences.getInstance())
        .setBool(UserPreferenceKey.ShowStatusTab.toString(), value);
  }

  Future<bool> getVPNSwitchInstructionsViewed() async {
    return (await SharedPreferences.getInstance()).getBool(
            UserPreferenceKey.VPNSwitchInstructionsViewed.toString()) ??
        false;
  }

  Future<bool> setVPNSwitchInstructionsViewed(bool value) async {
    return (await SharedPreferences.getInstance()).setBool(
        UserPreferenceKey.VPNSwitchInstructionsViewed.toString(), value);
  }

  Future<bool> getFirstLaunchInstructionsViewed() async {
    return (await SharedPreferences.getInstance()).getBool(
            UserPreferenceKey.FirstLaunchInstructionsViewed.toString()) ??
        false;
  }

  Future<bool> setFirstLaunchInstructionsViewed(bool value) async {
    return (await SharedPreferences.getInstance()).setBool(
        UserPreferenceKey.FirstLaunchInstructionsViewed.toString(), value);
  }

  ObservablePreference<bool> allowNoHopVPN = ObservablePreference(
      key: UserPreferenceKey.AllowNoHopVPN,
      loadValue: (key) async {
        return (await SharedPreferences.getInstance())
                .getBool(UserPreferenceKey.AllowNoHopVPN.toString()) ??
            false;
      },
      storeValue: (key, value) async {
        return (await SharedPreferences.getInstance())
            .setBool(UserPreferenceKey.AllowNoHopVPN.toString(), value);
      });

  /// Stores the shared, single, outstanding PAC transaction or null if there is none.
  ObservablePreference<PacTransaction> pacTransaction = ObservablePreference(
      key: UserPreferenceKey.PacTransaction,
      loadValue: (key) async {
        String value = await readStringForKey(key);
        return value != null
            ? PacTransaction.fromJson(jsonDecode(value))
            : null;
      },
      storeValue: (key, tx) {
        String value = tx != null ? jsonEncode(tx) : null;
        return writeStringForKey(key, value);
      });
}

enum UserPreferenceKey {
  PromptedForVPNPermission,
  Budget,
  Circuit,
  RecentlyDeletedHops,
  UserConfig,
  Keys,
  DefaultCurator,
  QueryBalances,
  DesiredVPNState,
  ShowStatusTab,
  VPNSwitchInstructionsViewed,
  FirstLaunchInstructionsViewed,
  AllowNoHopVPN,
  PacTransaction
}
