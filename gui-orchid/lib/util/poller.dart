import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../api/orchid_log.dart';

/*
    Poller.call(foo).every(seconds: 5).dispose(disposal);
    Poller.call(foo).nowAndEvery(seconds: 5).dispose(disposal);
 */
class Poller {
  final VoidCallback func;
  Timer? _timer;

  Poller(this.func);

  static Poller call(VoidCallback func) {
    return Poller(func);
  }

  /// Poll at the specified interval starting after one interval.
  /// (This is the default behavior of Timer).
  Poller every({int? seconds, int? minutes, int? hours}) {
    assert(seconds != null || minutes != null || hours != null);
    _timer?.cancel();
    var duration = Duration(
        seconds: seconds ?? 0, minutes: minutes ?? 0, hours: hours ?? 0);
    if (duration.inMilliseconds <= 0) {
      throw Exception("invalid duration: $duration");
    }
    _timer = Timer.periodic(duration, _poll);
    return this;
  }

  /// Invoke once immediately and then at the specified interval
  Poller nowAndEvery({int? seconds, int? minutes, int? hours}) {
    _poll(null);
    return every(seconds: seconds, minutes: minutes, hours: hours);
  }

  void _poll(_) {
    try {
      func();
    } catch (e) {
      log("Poller error: $e");
    }
  }

  Poller dispose(List disposal) {
    disposal.add(this);
    return this;
  }

  void cancel() {
    _timer?.cancel();
  }
}
