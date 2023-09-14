import 'package:flutter/material.dart';
import 'package:orchid/api/preferences/user_preferences.dart';
import 'package:rxdart/rxdart.dart';

class ObservablePreference<T> {
  UserPreferenceKey key;
  bool _initialized = false;

  bool get initialized {
    return _initialized;
  }

  BehaviorSubject<T> _subject = BehaviorSubject();

  T? Function(UserPreferenceKey key) getValue;
  Future Function(UserPreferenceKey key, T? value) putValue;

  ObservablePreference(
      {required this.key, required this.getValue, required this.putValue});

  /// Subscribe to the value stream. This method ensures that the stream is
  /// initialized with the first value from the underlying user preference,
  /// however using builder() ensures that the value is passed as the initial data
  /// value to the UI a StreamBuilder.
  Stream<T> stream() {
    _ensureInitialized();
    return _subject.asBroadcastStream();
  }

  /// Return a stream builder for this preference that supplies the current value
  /// as the initial stream data (thus avoiding a null data build pass).
  ObservablePreferenceBuilder<T> builder(Widget Function(T? t) builder) {
    return ObservablePreferenceBuilder(preference: this, builder: builder);
  }

  T? get() {
    if (_initialized && _subject.hasValue) {
      return _subject.value;
    } else {
      T? value = getValue(key);
      _broadcast(value);
      return value;
    }
  }

  Future<T?> set(T? value) async {
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
    await set(null);
  }

  // This can be called during startup to block until the property has been initialized
  void _ensureInitialized() {
    get();
  }

  void _broadcast(T? value) {
    _initialized = true;
    // TODO: We should allow nulls in the streams
    if (value != null) {
      _subject.add(value);
    }
    // _subject.add(value);
  }
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
              if (value == null) {
                throw Exception("value may not be null");
              }
              return (UserPreferences().sharedPreferences())
                  .setBool(key.toString(), value);
            });
}

/// A builder stream building widget for an observable preference.
/// This class codifies the fact that user preference data can be fetched
/// synchronously and provided in the stream initial data.
class ObservablePreferenceBuilder<T> extends StatelessWidget {
  final Widget Function(T? t) builder;
  final T? initialData;
  final Stream<T> stream;

  ObservablePreferenceBuilder({
    Key? key,
    required ObservablePreference<T> preference,
    required this.builder,
  })  : this.initialData = preference.get(),
        this.stream = preference.stream(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
        initialData: initialData,
        stream: stream,
        builder: (context, snapshot) {
          return builder(snapshot.data);
        });
  }
}
