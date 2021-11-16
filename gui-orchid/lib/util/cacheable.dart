import 'package:flutter/foundation.dart';
import 'package:orchid/api/orchid_log_api.dart';

bool _logCaching = false;

class Cache<K, T> {
  final Duration duration;
  final Map<K, _Cached<T>> map = {};
  final String name; // for logging

  Cache({@required this.duration, this.name = 'cache'});

  Future<T> get({
    K key,
    Future<T> Function(K key) producer,
    bool refresh = false,
  }) async {
    var cached = map[key];
    if (!refresh && cached != null && !cached.isExpired(duration)) {
      log("cache: ($name): returning cached value for  $key");
      return cached.value;
    }
    log("cache: ($name):${refresh ? ' [refresh]' : ''} updating value for: $key");
    Future<T> value = producer(key);
    map[key] = _Cached(value);
    return value;
  }

  void clean() {
    map.removeWhere((key, value) => value.isExpired(duration));
  }

  void log(String text) {
    if (_logCaching) {
      OrchidLogAPI.defaultLogAPI.write(text);
    }
  }
}

/// A cache that holds a single item
class SingleCache<T> {
  final Duration duration;
  final String name; // for logging
  _Cached<T> cached;

  SingleCache({@required this.duration, this.name = 'cache'});

  Future<T> get({
    Future<T> Function() producer,
    bool refresh = false,
  }) async {
    if (!refresh && cached != null && !cached.isExpired(duration)) {
      log("cache: ($name): returning cached value");
      return cached.value;
    }
    log("cache: ($name):${refresh ? ' [refresh]' : ''} updating value");
    Future<T> value = producer();
    cached = _Cached(value);
    return value;
  }
  
  void log(String text) {
    if (_logCaching) {
      OrchidLogAPI.defaultLogAPI.write(text);
    }
  }
}

/// A cached item with expiration period
class _Cached<T> {
  DateTime time = DateTime.now();
  Future<T> value;

  _Cached(this.value);

  bool isExpired(Duration duration) {
    return DateTime.now().difference(time) > duration;
  }
}
