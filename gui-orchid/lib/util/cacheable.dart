import 'package:flutter/foundation.dart';
import 'package:orchid/api/orchid_log_api.dart';

class Cache<K, T> {
  final Duration duration;
  final Map<K, _Cached<T>> map = {};
  final String name; // for logging

  Cache({@required this.duration, this.name = "cache"});

  Future<T> get(
      {K key, Future<T> Function(K key) producer, bool refresh = false}) async {
    var cached = map[key];
    if (!refresh && cached != null && !cached.isExpired(duration)) {
      log("cache ($name): returning cached value for  $key");
      return cached.value;
    }
    Future<T> value = producer(key);
    log("cache ($name): ${refresh ? ' [refresh]' : ''} updating value for: $key");
    map[key] = _Cached(value);
    return value;
  }

  void clean() {
    map.removeWhere((key, value) => value.isExpired(duration));
  }
}

/*
/// A cache that holds a single value
class Cacheable<T> {
  final Duration duration;
  _Cached<T> cached;

  Cacheable({@required this.duration});

  Future<T> get({Future<T> Function() producer, bool refresh = false}) async {
    if (!refresh && cached != null && !cached.isExpired(duration)) {
      log("cacheable: returning cached value: ${cached.value}");
      return cached.value;
    }
    Future<T> value = producer();
    log("cacheable: updating value");
    cached = _Cached(value);
    return value;
  }
}
 */

/// A cached item with expiration period
class _Cached<T> {
  DateTime time = DateTime.now();
  Future<T> value;

  _Cached(this.value);

  bool isExpired(Duration duration) {
    return DateTime.now().difference(time) > duration;
  }
}
