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

  Future<bool> getWalkthroughCompleted() async {
    return (await SharedPreferences.getInstance())
            .getBool(UserPreferenceKey.WalkthroughCompleted.toString()) ??
        false;
  }

  Future<bool> setWalkthroughCompleted(bool value) async {
    return (await SharedPreferences.getInstance())
        .setBool(UserPreferenceKey.WalkthroughCompleted.toString(), value);
  }

  Future<bool> getPromptedForVPNPermission() async {
    return (await SharedPreferences.getInstance())
            .getBool(UserPreferenceKey.PromptedForVPNPermission.toString()) ??
        false;
  }

  Future<bool> setPromptedForVPNPermission(bool value) async {
    return (await SharedPreferences.getInstance())
        .setBool(UserPreferenceKey.PromptedForVPNPermission.toString(), value);
  }
}

enum UserPreferenceKey { WalkthroughCompleted, PromptedForVPNPermission }
