import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static final UserPreferences _singleton = new UserPreferences._internal();

  factory UserPreferences() {
    return _singleton;
  }

  UserPreferences._internal() {
    debugPrint("constructed user prefs API");
  }

  Future<bool> getWalkthroughCompleted() async {
    return (await SharedPreferences.getInstance())
        .getBool(UserPreferenceKey.WalkthroughCompleted.toString());
  }

  void setWalkthroughCompleted(bool value) async {
    (await SharedPreferences.getInstance())
        .setBool(UserPreferenceKey.WalkthroughCompleted.toString(), value);
  }
}

enum UserPreferenceKey { WalkthroughCompleted }

