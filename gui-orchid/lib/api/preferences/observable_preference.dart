import 'package:flutter/material.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../orchid_log_api.dart';

class ObservablePreference<T> {
  UserPreferenceKey key;
  bool _initialized = false;

  bool get initialized {
    return _initialized;
  }

  BehaviorSubject<T> _subject = BehaviorSubject();

  Future<T> Function(UserPreferenceKey key) loadValue;
  Future Function(UserPreferenceKey key, T value) storeValue;

  /// Note: If you use this with a StreamBuilder you must call ensureInitialized
  /// Note: during your initialization to ensure that a current value is loaded.
  Stream<T> stream() {
    return _subject.asBroadcastStream();
  }

  Future<Stream<T>> streamAsync() async {
    await ensureInitialized();
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

  Future<T> set(T value) async {
    await storeValue(key, value);
    _broadcast(value);
    return value;
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

/// An observable boolean value which returns false (or a specified default)
/// when uninitialized
class ObservableBoolPreference extends ObservablePreference<bool> {
  final bool defaultValue;

  ObservableBoolPreference(UserPreferenceKey key, {this.defaultValue = false})
      : super(
            key: key,
            loadValue: (key) async {
              return (await SharedPreferences.getInstance())
                      .getBool(key.toString()) ??
                  defaultValue;
            },
            storeValue: (key, value) async {
              return (await SharedPreferences.getInstance())
                  .setBool(key.toString(), value);
            });
}
