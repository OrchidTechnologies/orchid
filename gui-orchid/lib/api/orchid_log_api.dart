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
  pattern.allMatches(text).forEach((match) => log(match.group(0)));
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
  List<String> get();

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

  LogLine(this.text)
      : this.id = nextId++,
        this.date = DateTime.now();

  String withDate() {
    final timeStamp = DateTime.now().toIso8601String();
    return timeStamp + ': ' + text;
  }

  @override
  String toString() {
    return withDate();
  }
}

/// Transient, in-memory log implementation.
class MemoryOrchidLogAPI extends OrchidLogAPI {
  static int maxLines = 5000;

  List<String> _buffer = <String>[];

  /// Get the current log contents.
  List<String> get() {
    return List.unmodifiable(_buffer);
    // var data = testLogData;
    // data += data;
    // data += data;
    // data += data;
    // data += data;
    // return data;
  }

  /// Write the text to the log.
  void write(String textIn) async {
    String timeStamp = DateTime.now().toIso8601String();
    String text = timeStamp + ': ' + textIn;

    debugPrint("LOG: $text");
    if (!_enabled) {
      return;
    }

    _buffer.add(text = text.endsWith('\n') ? text : (text + '\n'));

    // truncate if needed
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
