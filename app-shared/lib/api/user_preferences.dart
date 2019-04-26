import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}

enum UserPreferenceKey {
  WalkthroughCompleted,
  PromptedForVPNPermission,
  PromptedToLinkWallet,
  LinkWalletAcknowledged,
  PromptedForVPNCredentials
}
