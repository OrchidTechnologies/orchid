import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqflite.dart';
import '../orchid_api.dart';
import 'iana.dart';
import 'query_parser.dart';

class AnalysisDb {
  static AnalysisDb _shared = AnalysisDb._init();
  static final String unknown = "???"; // Localize

  final BehaviorSubject<bool> update = BehaviorSubject();
  Database _db;

  AnalysisDb._init();

  factory AnalysisDb() {
    return _shared;
  }

  Future<Database> _getDb() async {
    if (_db != null && _db.isOpen) {
      return _db;
    }
    try {
      String dbPath = (await OrchidAPI().groupContainerPath()) + '/analysis.db';
      _db = await openDatabase(dbPath, readOnly: false);
    } catch (err) {
      debugPrint("Error opening analysis db: $err");
      return null;
    }
    await _db.execute("PRAGMA journal_mode = wal");
    await _db.execute("PRAGMA secure_delete = on");
    await _db.execute("PRAGMA synchronous = full");
    return _db;
  }

  Future<List<FlowEntry>> query({String filterText}) async {
    var db = await _getDb();
    if (db == null) {
      return List();
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
      return List();
    }
  }

  Future<void> clear() async {
    Database db = await _getDb();
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

  String _fromProtocol(int number) {
    if (number == null) {
      return unknown;
    }
    return IANA.protocol[number] ?? unknown;
  }

  void dispose() {
    _db.close();
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
  final String hostname;

  FlowEntry(
      {this.rowId,
      this.start,
      this.layer4,
      this.protocol,
      this.src_addr,
      this.src_port,
      this.dst_addr,
      this.dst_port,
      this.hostname});
}

