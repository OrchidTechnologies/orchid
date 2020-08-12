import 'package:flutter/material.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:rxdart/rxdart.dart';

import '../orchid_log_api.dart';

class ObservablePreference<T> {
  UserPreferenceKey key;
  bool _initialized = false;
  BehaviorSubject<T> _subject = BehaviorSubject();

  Future<T> Function(UserPreferenceKey key) loadValue;
  Future Function(UserPreferenceKey key, T value) storeValue;

  // Note: If called during intialization the caller should await a get() first
  // Note: to ensure that the preference has been created.
  Stream<T> stream() {
    return _subject.asBroadcastStream();
  }

  Future<T> get() async {
    if (_initialized) {
      return _subject.value;
    } else {
      T value = await loadValue(key);
      _broadcast(value);
      return value;
    }
  }

  Future<bool> hasValue() async {
    return (await get()) != null;
  }

  Future<void> set(T value) async {
    await storeValue(key, value);
    _broadcast(value);
  }

  Future<void> clear() async {
    log("iap: clearing pac tx");
    return set(null);
  }

  // This can be called during startup to block until the property has been initialized
  Future<void> ensureInitialized() async {
    return await get();
  }

  void _broadcast(value) {
    _initialized = true;
    _subject.add(value);
  }

  ObservablePreference(
      {@required this.key,
        @required this.loadValue,
        @required this.storeValue});
}

class ObservableStringPreference extends ObservablePreference<String> {
  ObservableStringPreference(UserPreferenceKey key)
      : super(
      key: key,
      loadValue: (key) {
        return UserPreferences.readStringForKey(key);
      },
      storeValue: (key, value) {
        return UserPreferences.writeStringForKey(key, value);
      });
}

