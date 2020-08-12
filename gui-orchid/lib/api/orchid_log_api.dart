import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

import 'orchid_api.dart';

void log(String text) {
  OrchidAPI().logger().write(text);
}

/// Logging support, if any, implemented by the channel API.
abstract class OrchidLogAPI {

  /// Notify observers when the log file has updated.
  PublishSubject<void> logChanged = PublishSubject<void>();

  /// Enable or disable logging.
  Future<void> setEnabled(bool enabled);

  /// Get the logging enabled status.
  Future<bool> getEnabled();

  /// Get the current log contents.
  Future<String> get();

  /// Write the text to the log.
  void write(String text);

  /// Clear the log file.
  void clear();
}

/// Transient, in-memory log implementation.
class MemoryOrchidLogAPI extends OrchidLogAPI {
  static int maxLines = 5000;
  bool _enabled = true;

  // Note: All Dart code runs in a single Isolate by default so explicit
  // Note: locking or synchronization should not be needed here.
  List<String> _buffer = List<String>();

  /// Notify observers when the log file has updated.
  PublishSubject<void> logChanged = PublishSubject<void>();

  /// Enable or disable logging.
  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    logChanged.add(null);
  }

  /// Get the logging enabled status.
  Future<bool> getEnabled() async {
    return _enabled;
  }

  /// Get the current log contents.
  Future<String> get() async {
    return _buffer.join();
  }

  /// Write the text to the log.
  void write(String textIn) async {
    String timeStamp = DateTime.now().toIso8601String();
    String text = timeStamp + ': ' +textIn;
    
    debugPrint("LOG: $text");
    if (!_enabled) {
      return;
    }

    _buffer.add(text = text.endsWith('\n') ? text : (text + '\n'));

    // truncate if needed
    if (_buffer.length > maxLines) {
      _buffer.removeAt(0);
    }

    logChanged.add(null);
  }

  /// Clear the log file.
  void clear() {
    _buffer.clear();
    logChanged.add(null);
  }
}
