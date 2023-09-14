import 'package:flutter/material.dart';

void log(String text) {
  OrchidLogAPI.defaultLogAPI.write(text);
}

void logDetail(String text) {
  log('[detail]: ' + text);
}

/// Work around log line length limits
void logWrapped(String text) {
  final pattern = new RegExp('.{1,800}');
  pattern.allMatches(text).forEach((match) => log(match.group(0) ?? ''));
}

/// Logging support, if any, implemented by the channel API.
abstract class OrchidLogAPI {
  static OrchidLogAPI defaultLogAPI = MemoryOrchidLogAPI();

  bool _enabled = true;

  /// Notify observers when the log file has updated.
  final logChanged = ChangeNotifier();

  /// Enable or disable logging.
  set enabled(bool value) {
    _enabled = value;
    logChanged.notifyListeners();
  }

  /// Get the logging enabled status.
  bool get enabled {
    return _enabled;
  }

  /// Get the current log contents.
  List<LogLine> get();

  /// Write the text to the log.
  void write(String text);

  /// Clear the log file.
  void clear();
}

class LogLine {
  static int nextId = 0;

  // A consecutive incrementing id
  final int id;
  final DateTime date;
  final String text;

  LogLine(String text)
      : this.text = text.trim(),
        this.id = nextId++,
        this.date = DateTime.now();

  String toStringWithDate() {
    final timeStamp = date.toIso8601String();
    return timeStamp + ': ' + text;
  }

  @override
  String toString() {
    return toStringWithDate();
  }
}

/// Transient, in-memory log implementation.
class MemoryOrchidLogAPI extends OrchidLogAPI {
  static int maxLines = 5000;

  List<LogLine> _buffer = [];

  /*
  MemoryOrchidLogAPI() {
    var data = testLogData;
    data += data;
    data += data;
    data += data;
    data += data;
    _buffer = data.map((e) => LogLine(e)).toList();
  }
   */

  @override
  set enabled(bool value) {
    if (value == false) {
      _buffer = [];
    }
    super.enabled = value;
  }

  /// Get the current log contents.
  List<LogLine> get() {
    return List.unmodifiable(_buffer);
  }

  /// Write the text to the log.
  void write(String text) async {
    final line = LogLine(text);

    // always print to syslog
    debugPrint("LOG: ${line.toStringWithDate()}");
    if (!_enabled) {
      return;
    }

    _buffer.add(line);

    // rotater buffer if needed
    if (_buffer.length > maxLines) {
      _buffer.removeAt(0);
    }

    logChanged.notifyListeners();
  }

  /// Clear the log file.
  void clear() {
    _buffer.clear();
    logChanged.notifyListeners();
  }
}
