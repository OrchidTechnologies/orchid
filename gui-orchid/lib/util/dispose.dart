import 'dart:async';
import 'package:orchid/api/orchid_log.dart';

extension DisposeTimerExtensions on Timer {
  Timer dispose(List disposal) {
    disposal.add(this);
    return this;
  }
}

extension DisposeStreamExtensions on StreamSubscription {
  StreamSubscription dispose(List disposal) {
    disposal.add(this);
    return this;
  }
}

extension DisposeListExtensions on List {
  void dispose() {
    this.forEach((e) {
      try {
        e.cancel();
      } catch (err) {
        log("Error disposing of object: $e");
      }
    });
  }
}
