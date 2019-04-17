import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orchid/api/orchid_api.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

/// Provide access to the application level log file stored in the local filesystem.
class LogFile {
  static final LogFile _singleton = LogFile._internal();
  static final String _fileName = "orchid_log.txt";

  factory LogFile() {
    return _singleton;
  }

  LogFile._internal() {
    debugPrint("constructed logfile singleton");

    // Listen to the channel API for published log messages.
    OrchidAPI().log.listen((logText) {
      write(logText);
    });
  }

  /// Notify observers when the log file has updated.
  /// Note: We could provide the contents as a string here but I'm concerned about
  /// how large the file might become and whether we'll need a way to read it in chunks.
  PublishSubject<void> logChanged = PublishSubject<void>();

  /// Get the current contents of the log file.
  Future<String> get() async {
    File file = await _getFile();
    return file.readAsString();
  }

  /// TODO: I believe these will be implicitly synchronized by the async queue
  /// TODO: but I want to confirm that.
  /// Write the text to the persistent log file.
  void write(String text) async {
    debugPrint("LOG: $text");
    text = text.endsWith('\n') ? text : (text+'\n');
    await (await _getFile()).writeAsString(text, mode: FileMode.writeOnlyAppend);
    logChanged.add(null);
  }

  void clear() async {
    await (await _getFile()).delete();
    logChanged.add(null);
  }

  Future<File> _getFile() async {
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = File('$dir/$_fileName');
    bool exists = await file.exists();
    if (exists) {
      return file;
    } else {
      return file.create();
    }
  }

}

