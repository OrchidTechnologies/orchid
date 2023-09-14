import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
    _timer = Timer.periodic(
        Duration(
            seconds: seconds ?? 0, minutes: minutes ?? 0, hours: hours ?? 0),
        _poll);
    return this;
  }

  /// Invoke once immediately and then at the specified interval
  Poller nowAndEvery({int? seconds, int? minutes, int? hours}) {
    _poll(null);
    return every(seconds: seconds, minutes: minutes, hours: hours);
  }

  void _poll(_) {
    func();
  }

  Poller dispose(List disposal) {
    disposal.add(this);
    return this;
  }

  void cancel() {
    _timer?.cancel();
  }
}
