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

  T Function(UserPreferenceKey key) getValue;
  Future Function(UserPreferenceKey key, T value) putValue;

  /// Subscribe to the value stream *without* waiting for the value to be
  /// initialized.  The first values sent by the stream may be the uninititialized
  /// value, followed by the initialized value.
  Stream<T> stream() {
    _ensureInitialized();
    return _subject.asBroadcastStream();
  }

  // We used to support async value sources here.
  // If needed in the future we should make an ObservableAsyncPreference that
  // has different initialization requirements.
  /*
  /// Subscribe to the value stream after waiting for the value to be initialized.
  Future<Stream<T>> streamAsync() async {
    await ensureInitialized();
    return _subject.asBroadcastStream();
  }
   */

  T get() {
    if (_initialized) {
      return _subject.value;
    } else {
      T value = getValue(key);
      _broadcast(value);
      return value;
    }
  }

  Future<T> set(T value) async {
    await putValue(key, value);
    // If the value is null attempt to load it again allowing the store method
    // to transform it if needed.
    _broadcast(value ?? getValue(key));
    return value;
  }

  bool hasValue() {
    return get() != null;
  }

  Future<void> clear() async {
    return set(null);
  }

  // This can be called during startup to block until the property has been initialized
  void _ensureInitialized() {
    get();
  }

  void _broadcast(value) {
    _initialized = true;
    _subject.add(value);
  }

  ObservablePreference(
      {@required this.key, @required this.getValue, @required this.putValue});
}

class ObservableStringPreference extends ObservablePreference<String> {
  ObservableStringPreference(UserPreferenceKey key)
      : super(
            key: key,
            getValue: (key) {
              return UserPreferences().getStringForKey(key);
            },
            putValue: (key, value) {
              return UserPreferences().putStringForKey(key, value);
            });
}

/// An observable boolean value which returns false (or a specified default)
/// when uninitialized
class ObservableBoolPreference extends ObservablePreference<bool> {
  final bool defaultValue;

  ObservableBoolPreference(UserPreferenceKey key, {this.defaultValue = false})
      : super(
            key: key,
            getValue: (key) {
              return (UserPreferences().sharedPreferences())
                      .getBool(key.toString()) ??
                  defaultValue;
            },
            putValue: (key, value) async {
              return (UserPreferences().sharedPreferences())
                  .setBool(key.toString(), value);
            });
}

class ReleaseVersion {
  final int version;

  ReleaseVersion(this.version);

  ReleaseVersion.resetFirstLaunch() : this.version = null;

  /// This is represents a first launch of the app since the V1 UI.
  bool get isFirstLaunch {
    return version == null;
  }

  // Compare versions or return true if first launch.
  bool isOlderThan(ReleaseVersion other) {
    return version == null || version < other.version;
  }

  @override
  String toString() {
    return 'ReleaseVersion{version: $version}';
  }
}
