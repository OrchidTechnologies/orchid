import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:orchid/pages/circuit/circuit_hop.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'orchid_budget_api.dart';

class UserPreferences {
  static final UserPreferences _singleton = UserPreferences._internal();

  factory UserPreferences() {
    return _singleton;
  }

  UserPreferences._internal() {
    debugPrint("constructed user prefs API");
  }

  ///
  /// Onboarding pages related preferences
  /// TODO: Replace these with one StringList?
  ///

  /// Was the user shown the introductory pages as part of onboarding
  Future<bool> getWalkthroughCompleted() async {
    return (await SharedPreferences.getInstance())
            .getBool(UserPreferenceKey.WalkthroughCompleted.toString()) ??
        false;
  }

  /// Was the user shown the introductory pages as part of onboarding
  Future<bool> setWalkthroughCompleted(bool value) async {
    return (await SharedPreferences.getInstance())
        .setBool(UserPreferenceKey.WalkthroughCompleted.toString(), value);
  }

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

  Future<bool> getPromptedToLinkWallet() async {
    return (await SharedPreferences.getInstance())
            .getBool(UserPreferenceKey.PromptedToLinkWallet.toString()) ??
        false;
  }

  Future<bool> setPromptedToLinkWallet(bool value) async {
    return (await SharedPreferences.getInstance())
        .setBool(UserPreferenceKey.PromptedToLinkWallet.toString(), value);
  }

  Future<bool> getLinkWalletAcknowledged() async {
    return (await SharedPreferences.getInstance())
            .getBool(UserPreferenceKey.LinkWalletAcknowledged.toString()) ??
        false;
  }

  Future<bool> setLinkWalletAcknowledged(bool value) async {
    return (await SharedPreferences.getInstance())
        .setBool(UserPreferenceKey.LinkWalletAcknowledged.toString(), value);
  }


  Future<bool> getPromptedForVPNCredentials() async {
    return (await SharedPreferences.getInstance())
        .getBool(UserPreferenceKey.PromptedForVPNCredentials.toString()) ??
        false;
  }

  Future<bool> setPromptedForVPNCredentials(bool value) async {
    return (await SharedPreferences.getInstance())
        .setBool(UserPreferenceKey.PromptedForVPNCredentials.toString(), value);
  }


  /// Get the user's lottery pots primary address.  The value should have been
  /// set once upon app initialization.
  Future<String> getLotteryPotsPrimaryAddress() async {
    return (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.LotteryPotsPrimaryAddress.toString());
  }

  /// Set the lottery pots primary address. This should be called once upon
  /// app initialization. This method is currently guarded to prevent
  /// overwriting the stored value.
  Future<bool> setLotteryPotsPrimaryAddress(String value) async {
    return (await SharedPreferences.getInstance())
        .setString(UserPreferenceKey.LotteryPotsPrimaryAddress.toString(), value);
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
    print("getBudget found: $value");
    if (value == null) {
      return null;
    }
    return Budget.fromJson(jsonDecode(value));
  }

  Future<bool> setCircuit(Circuit circuit) async {
    String value = jsonEncode(circuit);
    return (await SharedPreferences.getInstance())
        .setString(UserPreferenceKey.Circuit.toString(), value);
  }

  Future<Circuit> getCircuit() async {
    String value = (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.Circuit.toString());
    if (value == null) {
      return null;
    }
    return Circuit.fromJson(jsonDecode(value));
  }


  // Get the user visible portion of the configuration file text.
  Future<String> getUserConfig() async {
    return (await SharedPreferences.getInstance())
        .getString(UserPreferenceKey.UserConfig.toString());
  }

  // Set the user visible portion of the configuration file text.
  Future<bool> setUserConfig(String value) async {
    return (await SharedPreferences.getInstance())
        .setString(UserPreferenceKey.UserConfig.toString(), value);
  }
}

enum UserPreferenceKey {
  WalkthroughCompleted,
  PromptedForVPNPermission,
  PromptedToLinkWallet,
  LinkWalletAcknowledged,
  PromptedForVPNCredentials,
  LotteryPotsPrimaryAddress,
  Budget,
  Circuit,
  UserConfig
}
