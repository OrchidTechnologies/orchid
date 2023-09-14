import 'package:flutter/cupertino.dart';
import 'package:orchid/vpn/monitoring/query_parser.dart';
import 'package:orchid/vpn/orchid_api.dart';
import 'package:orchid/vpn/orchid_api_mock.dart';
import 'package:orchid/api/orchid_log.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqflite.dart';

import 'iana.dart';

/// Traffic analysis database published by the Orchid extension.
class AnalysisDb {
  static String defaultAnalysisFilename = 'analysis.db';
  static AnalysisDb _shared = AnalysisDb._init();
  static final String unknown = "???"; // Localize

  final BehaviorSubject<bool?> update = BehaviorSubject();
  late Database? _db;

  AnalysisDb._init();

  factory AnalysisDb() {
    return _shared;
  }

  Future<Database?> getDb() async {
    if (_db != null && _db!.isOpen) {
      return _db;
    }
    try {
      if (OrchidAPI.mockAPI) {
        _db = await MockOrchidAPI.initInMemoryAnalysisDb();
      } else {
        String dbPath = (await OrchidAPI().groupContainerPath()) +
            '/$defaultAnalysisFilename';
        _db = await openDatabase(dbPath, readOnly: false);
      }
    } catch (err) {
      debugPrint("Error opening analysis db: $err");
      return null;
    }
    try {
      await _db!.execute("PRAGMA journal_mode = wal");
      await _db!.execute("PRAGMA secure_delete = on");
      await _db!.execute("PRAGMA synchronous = full");
    } catch (err) {
      log("analysis db: error in pragma: $err");
    }
    return _db;
  }

  Future<List<FlowEntry>> query({required String filterText}) async {
    var db;
    try {
      db = await getDb();
      if (db == null) {
        return [];
      }
    } catch (err) {
      log("Error querying analysis db: $err");
      return [];
    }
    String query = QueryParser(filterText).parse();
    //debugPrint("Query: $query");
    try {
      List<Map> list = await db.rawQuery(query);
      return list.map((row) {
        return FlowEntry(
            rowId: row['id'],
            start: fromJulianDate(row['start']),
            layer4: _fromProtocol(row['layer4']),
            protocol: row['protocol'],
            src_addr: _fromAddr(row['src_addr']),
            src_port: row['src_port'],
            dst_addr: _fromAddr(row['dst_addr']),
            dst_port: row['dst_port'],
            hostname: row['hostname']);
      }).toList(growable: false);
    } catch (err) {
      debugPrint("Analysis db: Error in query: $err");
      return [];
    }
  }

  Future<void> clear() async {
    Database? db = await getDb();
    if (db == null) {
      throw Exception();
    }
    await db.rawDelete('DELETE FROM flow');
    _notifyUpdate();
    return null;
  }

  void _notifyUpdate() {
    update.add(null);
  }

  String _fromAddr(int addr) {
    // Interpret negative values as unsigned
    if (addr < 0) {
      addr += (1 << 32);
    }
    var a1 = addr >> 24;
    var a2 = addr >> 16 & 255;
    var a3 = addr >> 8 & 255;
    var a4 = addr & 255;
    return "$a1.$a2.$a3.$a4";
  }

  String _fromProtocol(int? number) {
    if (number == null) {
      return unknown;
    }
    return IANA.protocol[number] ?? unknown;
  }

  void dispose() {
    _db?.close();
  }

  // https://github.com/zulfahmi93/dart-libcalendar/blob/master/lib/src/calendar_converter.dart
  static DateTime fromJulianDate(double jd) {
    final int _kMicrosecondsInOneDay = 86400000000;
    final int us = (jd * _kMicrosecondsInOneDay).toInt();
    final Duration duration = new Duration(microseconds: us);
    final DateTime _kJulianEpoch = new DateTime.utc(-4713, 11, 24, 12, 0);
    return _kJulianEpoch.add(duration);
  }
}

class FlowEntry {
  final int rowId;
  final DateTime start;
  final String layer4;
  final String protocol;
  final String src_addr;
  final int src_port;
  final String dst_addr;
  final int dst_port;
  final String? hostname;

  FlowEntry(
      {required this.rowId,
      required this.start,
      required this.layer4,
      required this.protocol,
      required this.src_addr,
      required this.src_port,
      required this.dst_addr,
      required this.dst_port,
      required this.hostname});
}
